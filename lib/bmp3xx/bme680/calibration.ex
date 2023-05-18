defmodule BMP3XX.BME680.Calibration do
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
    :par_h1,
    :par_h2,
    :par_h3,
    :par_h4,
    :par_h5,
    :par_h6,
    :par_h7,
    :par_gh1,
    :par_gh2,
    :par_gh3,
    :range_switching_error,
    :res_heat_range,
    :res_heat_val
  ]

  @type t :: %{
          par_t1: integer,
          par_t2: integer,
          par_t3: integer,
          par_p1: integer,
          par_p2: integer,
          par_p3: integer,
          par_p4: integer,
          par_p5: integer,
          par_p6: byte,
          par_p7: integer,
          par_p8: integer,
          par_p9: integer,
          par_p10: integer,
          par_h1: integer,
          par_h2: integer,
          par_h3: integer,
          par_h4: integer,
          par_h5: integer,
          par_h6: integer,
          par_h7: integer,
          par_gh1: integer,
          par_gh2: integer,
          par_gh3: integer,
          range_switching_error: integer,
          res_heat_range: 0..3,
          res_heat_val: integer
        }

  @doc """
  Parses the calibration data and compensates it.
  """
  @spec from_raw(<<_::336>>) :: t()
  def from_raw(
        <<par_t2::little-signed-16, par_t3::signed, _skip8D, par_p1::little-16,
          par_p2::little-signed-16, par_p3::signed, _skip93, par_p4::little-signed-16,
          par_p5::little-signed-16, par_p7::signed, par_p6::signed, _skip9A, _skip9B,
          par_p8::little-signed-16, par_p9::little-signed-16, par_p10, par_h2h, par_h2l::4,
          par_h1l::4, par_h1h, par_h3::signed, par_h4::signed, par_h5::signed, par_h6,
          par_h7::signed, par_t1::little-16, par_gh2::little-signed-16, par_gh1::signed,
          par_gh3::signed, res_heat_val::signed, _skip01, _::2, res_heat_range::2, _::4, _skip03,
          range_switching_error::signed-4, _::4>>
      ) do
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
      par_h1: par_h1h * 16 + par_h1l,
      par_h2: par_h2h * 16 + par_h2l,
      par_h3: par_h3,
      par_h4: par_h4,
      par_h5: par_h5,
      par_h6: par_h6,
      par_h7: par_h7,
      par_gh1: par_gh1,
      par_gh2: par_gh2,
      par_gh3: par_gh3,
      range_switching_error: range_switching_error,
      res_heat_range: res_heat_range,
      res_heat_val: res_heat_val
    )
  end
end
