# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BMP380.Measurement do
  @moduledoc false

  alias BMP3XX.BMP380.Calibration

  @spec from_raw(<<_::48>>, Calibration.t(), number) :: BMP3XX.Measurement.t()
  def from_raw(raw, calibration, sea_level_pa) do
    {pressure_pa, temperature_c} = pressure_pa_and_temperature_c_from_raw(raw, calibration)

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
  Calculate the temperature in Celsius. See docs:
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3.c#L2442
  """
  @spec pressure_pa_and_temperature_c_from_raw(<<_::48>>, Calibration.t()) :: {float, float}
  def pressure_pa_and_temperature_c_from_raw(raw, calibration) do
    <<raw_pressure::little-unsigned-24, raw_temperature::little-unsigned-24>> = raw

    t_lin = calc_t_lin(calibration, raw_temperature)

    temperature_c = t_lin * 25 / 16_384 / 100
    pressure_pa = pressure_pa_from_raw(calibration, raw_pressure, t_lin)

    {pressure_pa, temperature_c}
  end

  @doc """
  Calculate the pressure in Pascal. See docs:
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3.c#L2471
  """
  @spec pressure_pa_from_raw(Calibration.t(), number, number) :: float
  def pressure_pa_from_raw(calibration, raw_pressure, t_lin) do
    var1 = t_lin * t_lin
    var2 = var1 / 64
    var3 = var2 * t_lin / 256

    offset =
      with var4 <- calibration.par_p8 * var3 / 32,
           var5 <- calibration.par_p7 * var1 * 16,
           var6 <- calibration.par_p6 * t_lin * 4_194_304,
           do: calibration.par_p5 * 140_737_488_355_328 + var4 + var5 + var6

    sensitivity =
      with var4 <- calibration.par_p4 * var3 / 32,
           var5 <- calibration.par_p3 * var1 * 4,
           var6 <- (calibration.par_p2 - 16_384) * t_lin * 2_097_152,
           do: (calibration.par_p1 - 16_384) * 70_368_744_177_664 + var4 + var5 + var6

    var1 = sensitivity / 16_777_216 * raw_pressure
    var2 = calibration.par_p10 * t_lin
    var3 = var2 + 65_536 * calibration.par_p9
    var4 = var3 * raw_pressure / 8192

    var5 = raw_pressure * (var4 / 10) / 512 * 10
    var6 = calibration.par_p11 * raw_pressure * raw_pressure / 65_536
    var7 = var6 * raw_pressure / 128
    var8 = offset / 4 + var1 + var5 + var7
    var8 * 25 / 1_099_511_627_776 / 100
  end

  defp calc_t_lin(calibration, raw_temperature) do
    var1 = raw_temperature - 256 * calibration.par_t1
    var2 = calibration.par_t2 * var1
    var3 = var1 * var1
    var4 = var3 * calibration.par_t3
    var5 = var2 * 262_144 + var4
    var5 / 4_294_967_296
  end
end
