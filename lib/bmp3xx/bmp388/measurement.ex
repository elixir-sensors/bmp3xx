defmodule BMP3XX.BMP388.Measurement do
  @moduledoc false

  alias BMP3XX.BMP388.Calibration

  @spec from_raw_samples(<<_::48>>, Calibration.t()) :: BMP3XX.Measurement.t()
  def from_raw_samples(raw_samples, calibration) do
    {pressure_pa, temperature_c} =
      Calibration.raw_to_pressure_pa_and_temperature_c(calibration, raw_samples)

    %BMP3XX.Measurement{
      pressure_pa: pressure_pa,
      temperature_c: temperature_c,
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end

  @spec put_altitude_m(BMP3XX.Measurement.t(), number) :: BMP3XX.Measurement.t()
  def put_altitude_m(measurement, sea_level_pa) do
    altitude_m = BMP3XX.Calc.pressure_to_altitude(measurement.pressure_pa, sea_level_pa)
    %{measurement | altitude_m: altitude_m}
  end
end
