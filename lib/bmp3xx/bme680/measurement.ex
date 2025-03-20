# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BME680.Measurement do
  @moduledoc false

  alias BMP3XX.BME680.Calibration

  @spec from_raw(<<_::80>>, Calibration.t(), number) :: BMP3XX.Measurement.t()
  def from_raw(raw, calibration, sea_level_pa) do
    temperature_c = temperature_c_from_raw(raw, calibration)
    pressure_pa = pressure_pa_from_raw(raw, temperature_c, calibration)
    humidity_rh = humidity_rh_from_raw(raw, temperature_c, calibration)
    gas_resistance_ohms = gas_resistance_ohms_from_raw(raw, calibration)

    # Derived calculations
    altitude_m = BMP3XX.Calc.pressure_to_altitude(pressure_pa, sea_level_pa)
    dew_point_c = BMP3XX.Calc.dew_point(humidity_rh, temperature_c)

    %BMP3XX.Measurement{
      altitude_m: altitude_m,
      dew_point_c: dew_point_c,
      gas_resistance_ohms: gas_resistance_ohms,
      humidity_rh: humidity_rh,
      pressure_pa: pressure_pa,
      temperature_c: temperature_c,
      timestamp_ms: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Calculate the temperature in Celsius.
  """
  @spec temperature_c_from_raw(<<_::80>>, Calibration.t()) :: float
  def temperature_c_from_raw(<<_::80>> = raw, calibration) do
    <<_::20, _::4, raw_temperature::20, _::4, _::16, _::16>> = raw

    var1 = (raw_temperature / 16_384 - calibration.par_t1 / 1024) * calibration.par_t2

    var2 =
      (raw_temperature / 131_072 - calibration.par_t1 / 8192) *
        (raw_temperature / 131_072 - calibration.par_t1 / 8192) *
        calibration.par_t3 * 16

    (var1 + var2) / 5120
  end

  @doc """
  Calculate the pressure in Pascal.
  """
  @spec pressure_pa_from_raw(<<_::80>>, number, Calibration.t()) :: float
  def pressure_pa_from_raw(<<_::80>> = raw, temperature_c, calibration) do
    <<raw_pressure::20, _::4, _::20, _::4, _::16, _::16>> = raw

    t_fine = temperature_c * 5120

    var1 = t_fine / 2 - 64_000
    var2 = var1 * var1 * calibration.par_p6 / 131_072
    var2 = var2 + var1 * calibration.par_p5 * 2
    var2 = var2 / 4 + calibration.par_p4 * 65_536
    var1 = (calibration.par_p3 * var1 * var1 / 16_384 + calibration.par_p2 * var1) / 524_288
    var1 = (1 + var1 / 32_768) * calibration.par_p1
    press_comp = 1_048_576 - raw_pressure
    press_comp = (press_comp - var2 / 4096) * 6250 / var1
    var1 = calibration.par_p9 * press_comp * press_comp / 2_147_483_648
    var2 = press_comp * calibration.par_p8 / 32_768
    var3 = press_comp / 256 * press_comp / 256 * press_comp / 256 * calibration.par_p10 / 131_072

    press_comp + (var1 + var2 + var3 + calibration.par_p7 * 128) / 16
  end

  @spec humidity_rh_from_raw(<<_::80>>, number, Calibration.t()) :: number
  def humidity_rh_from_raw(<<_::80>> = raw, temperature_c, calibration) do
    <<_::20, _::4, _::20, _::4, raw_humidity::16, _::16>> = raw

    var1 = raw_humidity - (calibration.par_h1 * 16 + calibration.par_h3 / 2 * temperature_c)

    var2 =
      var1 *
        (calibration.par_h2 / 262_144 *
           (1 +
              calibration.par_h4 / 16_384 *
                temperature_c + calibration.par_h5 / 1_048_576 * temperature_c * temperature_c))

    var3 = calibration.par_h6 / 16_384
    var4 = calibration.par_h7 / 2_097_152
    h = var2 + (var3 + var4 * temperature_c) * var2 * var2

    min(100, max(0, h))
  end

  @gas_range_lookup1 {
    2_147_483_647.0,
    2_147_483_647.0,
    2_147_483_647.0,
    2_147_483_647.0,
    2_147_483_647.0,
    2_126_008_810.0,
    2_147_483_647.0,
    2_130_303_777.0,
    2_147_483_647.0,
    2_147_483_647.0,
    2_143_188_679.0,
    2_136_746_228.0,
    2_147_483_647.0,
    2_126_008_810.0,
    2_147_483_647.0,
    2_147_483_647.0
  }

  @gas_range_lookup2 {
    4_096_000_000.0,
    2_048_000_000.0,
    1_024_000_000.0,
    512_000_000.0,
    255_744_255.0,
    127_110_228.0,
    64_000_000.0,
    32_258_064.0,
    16_016_016.0,
    8_000_000.0,
    4_000_000.0,
    2_000_000.0,
    1_000_000.0,
    500_000.0,
    250_000.0,
    125_000.0
  }

  @spec gas_resistance_ohms_from_raw(<<_::80>>, Calibration.t()) :: float
  def gas_resistance_ohms_from_raw(raw, calibration) do
    <<_::64, raw_gas_resistance::10, _::2, raw_gas_range::4>> = raw

    var1 =
      (1340 + 5 * calibration.range_switching_error) *
        elem(@gas_range_lookup1, raw_gas_range) / 65_536

    var2 = raw_gas_resistance * 32_768 - 16_777_216 + var1
    var3 = elem(@gas_range_lookup2, raw_gas_range) * var1 / 512
    (var3 + var2 / 2) / var2
  end
end
