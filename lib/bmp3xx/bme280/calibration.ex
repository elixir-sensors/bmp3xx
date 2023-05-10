defmodule BMP3XX.BME280.Calibration do
  @moduledoc false

  defstruct [
    :dig_t1,
    :dig_t2,
    :dig_t3,
    :dig_p1,
    :dig_p2,
    :dig_p3,
    :dig_p4,
    :dig_p5,
    :dig_p6,
    :dig_p7,
    :dig_p8,
    :dig_p9,
    :dig_h1,
    :dig_h2,
    :dig_h3,
    :dig_h4,
    :dig_h5,
    :dig_h6
  ]

  @type t :: %{
          dig_t1: char,
          dig_t2: integer,
          dig_t3: integer,
          dig_p1: char,
          dig_p2: integer,
          dig_p3: integer,
          dig_p4: integer,
          dig_p5: integer,
          dig_p6: integer,
          dig_p7: integer,
          dig_p8: integer,
          dig_p9: integer,
          dig_h1: byte,
          dig_h2: integer,
          dig_h3: byte,
          dig_h4: non_neg_integer,
          dig_h5: non_neg_integer,
          dig_h6: integer
        }

  @doc """
  Parses the calibration data and compensates it.
  """
  @spec from_raw(<<_::264>>) :: t()
  def from_raw(
        <<dig_t1::little-16, dig_t2::little-signed-16, dig_t3::little-signed-16,
          dig_p1::little-16, dig_p2::little-signed-16, dig_p3::little-signed-16,
          dig_p4::little-signed-16, dig_p5::little-signed-16, dig_p6::little-signed-16,
          dig_p7::little-signed-16, dig_p8::little-signed-16, dig_p9::little-signed-16, _, dig_h1,
          dig_h2::little-signed-16, dig_h3, dig_h4h, dig_h4l::4, dig_h5l::4, dig_h5h,
          dig_h6::signed>>
      ) do
    __struct__(
      dig_t1: dig_t1,
      dig_t2: dig_t2,
      dig_t3: dig_t3,
      dig_p1: dig_p1,
      dig_p2: dig_p2,
      dig_p3: dig_p3,
      dig_p4: dig_p4,
      dig_p5: dig_p5,
      dig_p6: dig_p6,
      dig_p7: dig_p7,
      dig_p8: dig_p8,
      dig_p9: dig_p9,
      dig_h1: dig_h1,
      dig_h2: dig_h2,
      dig_h3: dig_h3,
      dig_h4: dig_h4h * 16 + dig_h4l,
      dig_h5: dig_h5h * 16 + dig_h5l,
      dig_h6: dig_h6
    )
  end
end
