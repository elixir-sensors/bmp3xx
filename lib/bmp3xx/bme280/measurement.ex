defmodule BMP3XX.BME280.Measurement do
  @moduledoc false

  alias BMP3XX.BME280.Calibration

  @spec from_raw(<<_::64>>, Calibration.t(), number) :: BMP3XX.Measurement.t()
  def from_raw(raw, calibration, sea_level_pa) do
    temperature_c = temperature_c_from_raw(raw, calibration)
    pressure_pa = pressure_pa_from_raw(raw, temperature_c, calibration)
    humidity_rh = humidity_from_raw(raw, temperature_c, calibration)

    # Derived calculations
    altitude_m = BMP3XX.Calc.pressure_to_altitude(pressure_pa, sea_level_pa)
    dew_point_c = BMP3XX.Calc.dew_point(humidity_rh, temperature_c)

    %BMP3XX.Measurement{
      altitude_m: altitude_m,
      dew_point_c: dew_point_c,
      humidity_rh: humidity_rh,
      pressure_pa: pressure_pa,
      temperature_c: temperature_c,
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Calculate the temperature in Celsius.
  """
  @spec temperature_c_from_raw(<<_::64>>, Calibration.t()) :: float
  def temperature_c_from_raw(<<_::64>> = raw, calibration) do
    <<_::20, _::4, raw_temperature::20, _::4, _::16>> = raw

    var1 = (raw_temperature / 16_384 - calibration.dig_t1 / 1024) * calibration.dig_t2

    var2 =
      (raw_temperature / 131_072 - calibration.dig_t1 / 8192) *
        (raw_temperature / 131_072 - calibration.dig_t1 / 8192) *
        calibration.dig_t3

    (var1 + var2) / 5120
  end

  @doc """
  Calculate the pressure in Pascal.
  """
  @spec pressure_pa_from_raw(<<_::64>>, number, Calibration.t()) :: float
  def pressure_pa_from_raw(<<_::64>> = raw, temperature_c, calibration) do
    <<raw_pressure::20, _::4, _::20, _::4, _::16>> = raw

    t_fine = temperature_c * 5120

    var1 = t_fine / 2 - 64_000
    var2 = var1 * var1 * calibration.dig_p6 / 32_768
    var2 = var2 + var1 * calibration.dig_p5 * 2
    var2 = var2 / 4 + calibration.dig_p4 * 65_536
    var1 = (calibration.dig_p3 * var1 * var1 / 524_288 + calibration.dig_p2 * var1) / 524_288
    var1 = (1 + var1 / 32_768) * calibration.dig_p1
    p = 1_048_576 - raw_pressure
    p = (p - var2 / 4096) * 6250 / var1
    var1 = calibration.dig_p9 * p * p / 2_147_483_648
    var2 = p * calibration.dig_p8 / 32_768
    p = p + (var1 + var2 + calibration.dig_p7) / 16

    p
  end

  @spec humidity_from_raw(<<_::64>>, number, Calibration.t()) :: number
  def humidity_from_raw(<<_::64>> = raw, temperature_c, calibration) do
    <<_::20, _::4, _::20, _::4, raw_humidity::16>> = raw

    t_fine = temperature_c * 5120
    var_h = t_fine - 76_800

    var_h =
      (raw_humidity - (calibration.dig_h4 * 64 + calibration.dig_h5 / 16_384 * var_h)) *
        (calibration.dig_h2 / 65_536 *
           (1 +
              calibration.dig_h6 / 67_108_864 * var_h *
                (1 + calibration.dig_h3 / 67_108_864 * var_h)))

    var_h = var_h * (1 - calibration.dig_h1 * var_h / 524_288)

    min(100, max(0, var_h))
  end
end
