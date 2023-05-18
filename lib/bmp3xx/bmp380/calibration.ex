defmodule BMP3XX.BMP380.Calibration do
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
  @spec from_raw(<<_::168>>) :: t()
  def from_raw(<<
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
end
