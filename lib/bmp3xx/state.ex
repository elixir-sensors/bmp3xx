defmodule BMP3XX.State do
  @moduledoc false
  # The internal state of the BMP3XX GenServer.

  defstruct last_measurement: nil,
            run_interval_ms: 1000,
            sensor_type: nil,
            sensor: nil,
            transport: nil

  @type t() :: %__MODULE__{
          last_measurement: BMP3XX.Measurement.t(),
          run_interval_ms: number,
          sensor: struct,
          sensor_type: BMP3XX.sensor_type(),
          transport: BMP3XX.Transport.t()
        }

  @spec new(keyword) :: t()
  def new(args) do
    transport = Keyword.fetch!(args, :transport)
    sea_level_pa = Keyword.fetch!(args, :sea_level_pa)
    sensor_type = Keyword.fetch!(args, :sensor_type)
    run_interval_ms = Keyword.fetch!(args, :run_interval_ms)
    sensor = build_sensor(sensor_type, transport, sea_level_pa)

    __struct__(
      last_measurement: nil,
      run_interval_ms: run_interval_ms,
      sensor_type: sensor_type,
      sensor: sensor,
      transport: transport
    )
  end

  defp build_sensor(sensor_type, transport, sea_level_pa)
       when is_atom(sensor_type) and is_struct(transport) and is_number(sea_level_pa) do
    sensor_type
    |> map_sensor_type_to_sensor()
    |> struct!(transport: transport)
    |> struct!(sea_level_pa: sea_level_pa)
  end

  defp map_sensor_type_to_sensor(:bmp180), do: %BMP3XX.BMP180{}
  defp map_sensor_type_to_sensor(:bmp280), do: %BMP3XX.BMP280{}
  defp map_sensor_type_to_sensor(:bme280), do: %BMP3XX.BME280{}
  defp map_sensor_type_to_sensor(:bme680), do: %BMP3XX.BME680{}
  defp map_sensor_type_to_sensor(:bmp380), do: %BMP3XX.BMP380{}
  defp map_sensor_type_to_sensor(:bmp390), do: %BMP3XX.BMP380{}

  @spec force_altitude(t(), number) :: t()
  def force_altitude(state, altitude_m) when is_number(altitude_m) do
    sea_level_pa = BMP3XX.Calc.sea_level_pressure(state.last_measurement.pressure_pa, altitude_m)
    put_in_sensor(state, :sea_level_pa, sea_level_pa)
  end

  @spec put_measurement(t(), BMP3XX.Measurement.t()) :: t()
  def put_measurement(state, measurement) do
    %{state | last_measurement: measurement}
  end

  @spec put_in_sensor(t(), atom, any) :: t()
  def put_in_sensor(state, key, value) when is_atom(key) do
    %{state | sensor: %{state.sensor | key => value}}
  end
end
