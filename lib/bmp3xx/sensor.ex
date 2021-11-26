defmodule BMP3XX.Sensor do
  @moduledoc false

  defstruct [:calibration, :last_measurement, :sea_level_pa, :sensor_mod, :transport]

  @type t :: %{
          calibration: map(),
          last_measurement: map(),
          sea_level_pa: number(),
          sensor_mod: atom(),
          transport: BMP3XX.Transport.t()
        }

  @callback init(BMP3XX.Sensor.t()) :: {:ok, BMP3XX.Sensor.t()} | {:error, any()}

  @callback read(BMP3XX.Sensor.t()) :: {:ok, BMP3XX.Measurement.t()} | {:error, any()}
end
