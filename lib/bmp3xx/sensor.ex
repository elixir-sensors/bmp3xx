defmodule BMP3XX.Sensor do
  @moduledoc false

  @type t :: %{
          calibration: map,
          last_measurement: map,
          sea_level_pa: number,
          sensor_type: atom,
          transport: pid
        }

  @callback init(BMP3XX.Sensor.t()) :: BMP3XX.Sensor.t() | :no_return

  @callback read(BMP3XX.Sensor.t()) :: {:ok, struct} | {:error, any}
end
