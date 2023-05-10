defmodule BMP3XX.BMP180.Measurement do
  @moduledoc false

  alias BMP3XX.BMP180.Calibration

  @two_2 :math.pow(2, 2)
  @two_4 :math.pow(2, 4)
  @two_8 :math.pow(2, 8)
  @two_11 :math.pow(2, 11)
  @two_12 :math.pow(2, 12)
  @two_13 :math.pow(2, 13)
  @two_15 :math.pow(2, 15)
  @two_16 :math.pow(2, 16)

  @spec from_raw(<<_::24>>, <<_::24>>, Calibration.t(), number) :: BMP3XX.Measurement.t()
  def from_raw(raw_t, raw_p, calibration, sea_level_pa) do
    temperature_c = temperature_c_from_raw(raw_t, calibration)
    pressure_pa = pressure_pa_from_raw(raw_p, temperature_c, calibration)

    # Derived calculations
    altitude_m = BMP3XX.Calc.pressure_to_altitude(pressure_pa, sea_level_pa)

    %BMP3XX.Measurement{
      altitude_m: altitude_m,
      pressure_pa: pressure_pa,
      temperature_c: temperature_c,
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Calculate the temperature in Celsius.
  """
  @spec temperature_c_from_raw(<<_::24>>, Calibration.t()) :: float
  def temperature_c_from_raw(<<raw_temp::16, _::8>>, calibration) do
    x1 = (raw_temp - calibration.ac6) * calibration.ac5 / @two_15
    x2 = calibration.mc * @two_11 / (x1 + calibration.md)
    b5 = x1 + x2
    (b5 + 8) / @two_4 / 10
  end

  @doc """
  Calculate the pressure in Pascal.
  """
  @spec pressure_pa_from_raw(<<_::24>>, number, Calibration.t()) :: float
  def pressure_pa_from_raw(<<raw_pressure::16, _::8>>, temperature_c, calibration) do
    b5 = temperature_c * 10 * @two_4 - 8
    b6 = b5 - 4000
    x1 = calibration.b2 * (b6 * b6) / @two_12 / @two_11
    x2 = calibration.ac2 * b6 / @two_11
    x3 = x1 + x2
    b3 = (calibration.ac1 * 4 + x3 + 2) / 4
    x1 = calibration.ac3 * b6 / @two_13
    x2 = calibration.b1 * (b6 * b6 / @two_12) / @two_16
    x3 = (x1 + x2 + 2) / @two_2
    b4 = calibration.ac4 * (x3 + 32_768) / @two_15
    b7 = (raw_pressure - b3) * 50_000
    p = p(b7, b4)
    x1 = p / @two_8 * (p / @two_8)
    x1 = x1 * 3038 / @two_16
    x2 = -7357 * p / @two_16
    p + (x1 + x2 + 3791) / @two_4
  end

  defp p(b7, b4) when b7 < 0x80000000, do: b7 * 2 / b4
  defp p(b7, b4), do: b7 / b4 * 2
end
