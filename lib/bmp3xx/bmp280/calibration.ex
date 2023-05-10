defmodule BMP3XX.BMP280.Calibration do
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
    :dig_p9
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
          dig_p9: integer
        }

  @doc """
  Parses the calibration data and compensates it.
  """
  @spec from_raw(<<_::192>>) :: t()
  def from_raw(
        <<dig_t1::little-16, dig_t2::little-signed-16, dig_t3::little-signed-16,
          dig_p1::little-16, dig_p2::little-signed-16, dig_p3::little-signed-16,
          dig_p4::little-signed-16, dig_p5::little-signed-16, dig_p6::little-signed-16,
          dig_p7::little-signed-16, dig_p8::little-signed-16, dig_p9::little-signed-16>>
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
      dig_p9: dig_p9
    )
  end
end
