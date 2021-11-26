defmodule BMP3XX do
  @moduledoc """
  Read pressure and temperature from a Bosch BMP388 or BMP390 sensor
  """

  use GenServer

  require Logger

  @type sensor_mod :: BMP3XX.BMP388 | BMP3XX.BMP390

  @type bus_address :: 0x76 | 0x77

  @typedoc """
  BMP3XX GenServer start_link options

  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:bus_address` - the address of the BMP3XX (defaults to 0x77)
  * `:sea_level_pa` - a starting estimate for the sea level pressure in Pascals
  """
  @type options() :: [
          name: GenServer.name(),
          bus_name: binary,
          bus_address: bus_address,
          sea_level_pa: number
        ]

  @sea_level_pa 100_000
  @default_bus_address 0x77
  @polling_interval_ms 1000

  @doc """
  Start a new GenServer for interacting with a BMP3XX

  Normally, you'll want to pass the `:bus_name` option to specify the I2C
  bus going to the BMP3XX.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: init_arg[:name])
  end

  @doc """
  Return the type of sensor

  This function returns the cached result of reading the ID register.
  if the part is recognized. If not, it returns the integer read.
  """
  @spec sensor_mod(GenServer.server()) :: sensor_mod()
  def sensor_mod(server \\ __MODULE__) do
    GenServer.call(server, :sensor_mod)
  end

  @doc """
  Measure the current temperature, pressure, altitude

  An error is return if the I2C transactions fail.
  """
  @spec measure(GenServer.server()) :: {:ok, struct} | {:error, any()}
  def measure(server \\ __MODULE__) do
    GenServer.call(server, :measure)
  end

  @doc """
  Update the sea level pressure estimate

  The sea level pressure should be specified in Pascals. The estimate
  is used for altitude calculations.
  """
  @spec update_sea_level_pressure(GenServer.server(), number) :: :ok
  def update_sea_level_pressure(server \\ __MODULE__, new_estimate) do
    GenServer.call(server, {:update_sea_level, new_estimate})
  end

  @doc """
  Force the altitude to a known value

  Altitude calculations depend on the accuracy of the sea level pressure estimate. Since
  the sea level pressure changes based on the weather, it needs to be kept up to date
  or altitude measurements can be pretty far off. Another way to set the sea level pressure
  is to report a known altitude. Call this function with the current altitude in meters.

  This function returns an error if the attempt to sample the current barometric
  pressure fails.
  """
  @spec force_altitude(GenServer.server(), number) :: :ok | {:error, any()}
  def force_altitude(server \\ __MODULE__, altitude_m) do
    GenServer.call(server, {:force_altitude, altitude_m})
  end

  @doc """
  Detect the type of sensor that is located at the I2C address

  If the sensor is a known BMP3XX sensor, the response will either contain
  `:bmp388` or `:bmp390`. If the sensor does not report back that it is one of
  those two types of sensors the return value will contain the id value that
  was reported back form the sensor.

  The bus address is likely going to be 0x77 (the default) or 0x76.
  """
  @spec detect(binary, bus_address) :: {:ok, sensor_mod()} | {:error, any()}
  def detect(bus_name, bus_address \\ @default_bus_address) do
    case transport_mod().open(bus_name: bus_name, bus_address: bus_address) do
      {:ok, transport} -> BMP3XX.Comm.sensor_type(transport)
      _error -> {:error, :device_not_found}
    end
  end

  @impl GenServer
  def init(args) do
    bus_name = Access.get(args, :bus_name, "i2c-1")
    bus_address = Access.get(args, :bus_address, @default_bus_address)
    sea_level_pa = Access.get(args, :sea_level_pa, @sea_level_pa)

    Logger.info(
      "[BMP3XX] Starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    )

    with {:ok, transport} <-
           transport_mod().open(bus_name: bus_name, bus_address: bus_address),
         {:ok, sensor_mod} <- BMP3XX.Comm.sensor_type(transport) do
      state = %BMP3XX.Sensor{
        calibration: nil,
        last_measurement: nil,
        sea_level_pa: sea_level_pa,
        sensor_mod: sensor_mod,
        transport: transport
      }

      {:ok, state, {:continue, :start_measuring}}
    else
      _error -> {:stop, :device_not_found}
    end
  end

  @impl GenServer
  def handle_continue(:start_measuring, state) do
    Logger.info("[BMP3XX] Initializing sensor type #{state.sensor_mod}")
    new_state = state |> init_sensor() |> read_and_put_new_measurement()
    Process.send_after(self(), :schedule_measurement, @polling_interval_ms)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) do
    if state.last_measurement do
      {:reply, {:ok, state.last_measurement}, state}
    else
      {:reply, {:error, :no_measurement}, state}
    end
  end

  def handle_call(:sensor_mod, _from, state) do
    {:reply, state.sensor_mod, state}
  end

  def handle_call({:update_sea_level, new_estimate}, _from, state) do
    {:reply, :ok, %{state | sea_level_pa: new_estimate}}
  end

  def handle_call({:force_altitude, altitude_m}, _from, state) do
    if state.last_measurement do
      sea_level = BMP3XX.Calc.sea_level_pressure(state.last_measurement.pressure_pa, altitude_m)
      {:reply, :ok, %{state | sea_level_pa: sea_level}}
    else
      {:reply, {:error, :no_measurement}, state}
    end
  end

  @impl GenServer
  def handle_info(:schedule_measurement, state) do
    Process.send_after(self(), :schedule_measurement, @polling_interval_ms)
    {:noreply, read_and_put_new_measurement(state)}
  end

  defp init_sensor(state) do
    case state.sensor_mod.init(state) do
      {:ok, state} -> state
      _error -> raise("Error initializing sensor")
    end
  end

  defp read_sensor(state) do
    state.sensor_mod.read(state)
  end

  defp read_and_put_new_measurement(state) do
    case read_sensor(state) do
      {:ok, measurement} ->
        %{state | last_measurement: measurement}

      {:error, reason} ->
        Logger.error("[BMP3XX] Error reading measurement: #{inspect(reason)}")
        state
    end
  end

  defp transport_mod() do
    Application.get_env(:bmp3xx, :transport_mod, BMP3XX.Transport.I2C)
  end
end
