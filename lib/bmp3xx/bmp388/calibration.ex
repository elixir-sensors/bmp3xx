defmodule BMP3XX.BMP388.Calibration do
  @moduledoc false

  defstruct [
    :par_t1,
    :par_t2,
    :par_t3,
    :par_p1,
    :par_p2,
    :par_p3,
    :par_p4,
    :par_p5,
    :par_p6,
    :par_p7,
    :par_p8,
    :par_p9,
    :par_p10,
    :par_p11
  ]

  @type t :: %__MODULE__{
          :par_t1 => char,
          :par_t2 => char,
          :par_t3 => integer,
          :par_p1 => integer,
          :par_p2 => integer,
          :par_p3 => integer,
          :par_p4 => integer,
          :par_p5 => char,
          :par_p6 => char,
          :par_p7 => integer,
          :par_p8 => integer,
          :par_p9 => integer,
          :par_p10 => integer,
          :par_p11 => integer
        }

  @doc """
  Parses the calibration data and compensates it. See docs:
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3_defs.h#L545
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3.c#L2416
  """
  @spec from_binary(<<_::168>>) :: t()
  def from_binary(<<
        par_t1::little-unsigned-16,
        par_t2::little-unsigned-16,
        par_t3::signed-8,
        par_p1::little-signed-16,
        par_p2::little-signed-16,
        par_p3::signed-8,
        par_p4::signed-8,
        par_p5::little-unsigned-16,
        par_p6::little-unsigned-16,
        par_p7::signed-8,
        par_p8::signed-8,
        par_p9::little-signed-16,
        par_p10::signed-8,
        par_p11::signed-8
      >>) do
    __struct__(
      par_t1: par_t1,
      par_t2: par_t2,
      par_t3: par_t3,
      par_p1: par_p1,
      par_p2: par_p2,
      par_p3: par_p3,
      par_p4: par_p4,
      par_p5: par_p5,
      par_p6: par_p6,
      par_p7: par_p7,
      par_p8: par_p8,
      par_p9: par_p9,
      par_p10: par_p10,
      par_p11: par_p11
    )
  end

  @doc """
  Calculate the temperature in Celsius. See docs:
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3.c#L2442
  """
  @spec raw_to_pressure_pa_and_temperature_c(t, <<_::48>>) :: {float(), float()}
  def raw_to_pressure_pa_and_temperature_c(calibration, raw_samples) do
    <<raw_pressure::little-unsigned-24, raw_temperature::little-unsigned-24>> = raw_samples

    t_lin = calculate_t_lin(calibration, raw_temperature)

    temperature_c = t_lin * 25 / 16_384 / 100
    pressure_pa = raw_to_pressure_pa(calibration, raw_pressure, t_lin)

    {pressure_pa, temperature_c}
  end

  defp calculate_t_lin(calibration, raw_temperature) do
    var1 = raw_temperature - 256 * calibration.par_t1
    var2 = calibration.par_t2 * var1
    var3 = var1 * var1
    var4 = var3 * calibration.par_t3
    var5 = var2 * 262_144 + var4
    var5 / 4_294_967_296
  end

  @doc """
  Calculate the pressure in Pascal. See docs:
  * https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3.c#L2471
  """
  @spec raw_to_pressure_pa(t(), number(), number()) :: float()
  def raw_to_pressure_pa(cal, raw_pressure, t_lin) do
    var1 = t_lin * t_lin
    var2 = var1 / 64
    var3 = var2 * t_lin / 256

    offset =
      with var4 <- cal.par_p8 * var3 / 32,
           var5 <- cal.par_p7 * var1 * 16,
           var6 <- cal.par_p6 * t_lin * 4_194_304,
           do: cal.par_p5 * 140_737_488_355_328 + var4 + var5 + var6

    sensitivity =
      with var4 <- cal.par_p4 * var3 / 32,
           var5 <- cal.par_p3 * var1 * 4,
           var6 <- (cal.par_p2 - 16_384) * t_lin * 2_097_152,
           do: (cal.par_p1 - 16_384) * 70_368_744_177_664 + var4 + var5 + var6

    var1 = sensitivity / 16_777_216 * raw_pressure
    var2 = cal.par_p10 * t_lin
    var3 = var2 + 65_536 * cal.par_p9
    var4 = var3 * raw_pressure / 8192

    var5 = raw_pressure * (var4 / 10) / 512 * 10
    var6 = cal.par_p11 * raw_pressure * raw_pressure / 65_536
    var7 = var6 * raw_pressure / 128
    var8 = offset / 4 + var1 + var5 + var7
    var8 * 25 / 1_099_511_627_776 / 100
  end
end
