defmodule BMP3XX.BMP388.Measurement do
  @moduledoc false

  alias BMP3XX.BMP388

  @spec from_raw_samples(<<_::48>>, BMP388.Calibration.t(), number()) :: BMP3XX.Measurement.t()
  def from_raw_samples(raw_samples, calibration, sea_level_pa) do
    {pressure_pa, temperature_c} =
      BMP388.Calibration.raw_to_pressure_pa_and_temperature_c(calibration, raw_samples)

    altitude_m = BMP3XX.Calc.pressure_to_altitude(pressure_pa, sea_level_pa)

    %BMP3XX.Measurement{
      altitude_m: altitude_m,
      pressure_pa: pressure_pa,
      temperature_c: temperature_c,
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end
end
