# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX do
  @moduledoc File.read!("README.md")
             |> String.split("<!-- MODULEDOC -->")
             |> Enum.fetch!(1)

  use GenServer
  alias BMP3XX.Comm
  alias BMP3XX.Sensor
  alias BMP3XX.State
  alias BMP3XX.Transport
  require Logger

  @type sensor_type :: bmp2_sensor_type | bmp3_sensor_type
  @type bmp2_sensor_type :: :bmp180 | :bmp280 | :bme280 | :bme680
  @type bmp3_sensor_type :: :bmp380 | :bmp390
  @type bus_address :: 0x76 | 0x77

  @typedoc """
  BMP3XX GenServer start_link options

  * `:name` - a name for the GenServer
  * `:bus_name` - which I2C bus to use (e.g., `"i2c-1"`)
  * `:bus_address` - the address of the BMP3XX (defaults to 0x77)
  * `:sea_level_pa` - a starting estimate for the sea level pressure in Pascals
  * `:retries` - the number of retries before failing (defaults to no retries)
  """
  @type option ::
          {:name, GenServer.name()}
          | {:bus_name, binary}
          | {:bus_address, bus_address}
          | {:sea_level_pa, number}
          | {:retries, number}

  @default_sea_level_pa 100_000
  @default_bus_name "i2c-1"
  @default_bus_address 0x77
  @default_run_interval_ms 1000

  @doc """
  Start a new GenServer for interacting with a BMP3XX

  Normally, you'll want to pass the `:bus_name` option to specify the I2C
  bus going to the BMP3XX.
  """
  @spec start_link([option]) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: init_arg[:name])
  end

  @doc """
  Measure the current temperature, pressure, altitude

  An error is return if the I2C transactions fail.
  """
  @spec measure(GenServer.server()) :: {:ok, struct} | {:error, any}
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
  @spec force_altitude(GenServer.server(), number) :: :ok | {:error, any}
  def force_altitude(server \\ __MODULE__, altitude_m) do
    GenServer.call(server, {:force_altitude, altitude_m})
  end

  @doc """
  Detect the type of sensor that is located at the I2C address

  The bus address is likely going to be 0x77 (the default) or 0x76.
  """
  @spec detect(binary, bus_address) :: {:ok, sensor_type} | {:error, any}
  def detect(bus_name, bus_address \\ @default_bus_address) do
    case Transport.open(bus_name, bus_address) do
      {:ok, transport} ->
        Comm.get_sensor_type(transport)

      _error ->
        {:error, :device_not_found}
    end
  end

  @impl GenServer
  def init(args) do
    bus_name = args[:bus_name] || @default_bus_name
    bus_address = args[:bus_address] || @default_bus_address
    sea_level_pa = args[:sea_level_pa] || @default_sea_level_pa
    run_interval_ms = args[:run_interval_ms] || @default_run_interval_ms
    i2c_options = Keyword.take(args, [:retries])

    "BMP3XX: starting on bus #{bus_name} at address #{inspect(bus_address, base: :hex)}"
    |> Logger.info()

    with {:ok, transport} <- Transport.open(bus_name, bus_address, i2c_options),
         {:ok, sensor_type} <- Comm.get_sensor_type(transport) do
      initial_state =
        State.new(
          run_interval_ms: run_interval_ms,
          transport: transport,
          sea_level_pa: sea_level_pa,
          sensor_type: sensor_type
        )

      {:ok, initial_state, {:continue, {:initialize_sensor, []}}}
    else
      {:error, error} ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_continue({:initialize_sensor, options}, state) do
    Logger.info("BMP3XX: initializing sensor type #{state.sensor_type}")

    case Sensor.init(state.sensor, options) do
      {:ok, initialized_sensor} ->
        new_state = %{state | sensor: initialized_sensor}

        # initial run
        send(self(), :perform_measurement)
        {:noreply, new_state}

      {:error, error} ->
        {:stop, error}
    end
  end

  def handle_continue(:schedule_next_run, state) do
    Process.send_after(self(), :perform_measurement, state.run_interval_ms)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:measure, _from, state) when is_nil(state.last_measurement) do
    {:reply, {:error, :no_measurement}, state}
  end

  def handle_call(:measure, _from, state) do
    {:reply, {:ok, state.last_measurement}, state}
  end

  def handle_call({:update_sea_level, sea_level_pa}, _from, state) do
    new_state = put_in(state.sensor, sea_level_pa: sea_level_pa)
    {:reply, :ok, new_state}
  end

  def handle_call({:force_altitude, _}, _from, state) when is_nil(state.last_measurement) do
    {:reply, {:error, :no_measurement}, state}
  end

  def handle_call({:force_altitude, altitude_m}, _from, state) do
    sea_level_pa = BMP3XX.Calc.sea_level_pressure(state.last_measurement.pressure_pa, altitude_m)
    new_state = State.put_in_sensor(state, :sea_level_pa, sea_level_pa)

    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_info(:perform_measurement, state) do
    new_state =
      case Sensor.measure(state.sensor) do
        {:ok, new_measurement} ->
          %{state | last_measurement: new_measurement}

        _ ->
          Logger.error("BMP3XX: could not read output")
          state
      end

    {:noreply, new_state, {:continue, :schedule_next_run}}
  end
end
