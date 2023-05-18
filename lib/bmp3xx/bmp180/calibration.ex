defmodule BMP3XX.BMP180.Calibration do
  @moduledoc false

  defstruct [
    :ac1,
    :ac2,
    :ac3,
    :ac4,
    :ac5,
    :ac6,
    :b1,
    :b2,
    :mb,
    :mc,
    :md
  ]

  @type t :: %{
          ac1: integer,
          ac2: integer,
          ac3: integer,
          ac4: char,
          ac5: char,
          ac6: char,
          b1: integer,
          b2: integer,
          mb: integer,
          mc: integer,
          md: integer
        }

  @doc """
  Parses the calibration data and compensates it.
  """
  @spec from_raw(<<_::176>>) :: t()
  def from_raw(
        <<ac1::big-signed-16, ac2::big-signed-16, ac3::big-signed-16, ac4::big-unsigned-16,
          ac5::big-unsigned-16, ac6::big-unsigned-16, b1::big-signed-16, b2::big-signed-16,
          mb::big-signed-16, mc::big-signed-16, md::big-signed-16>>
      ) do
    __struct__(
      ac1: ac1,
      ac2: ac2,
      ac3: ac3,
      ac4: ac4,
      ac5: ac5,
      ac6: ac6,
      b1: b1,
      b2: b2,
      mb: mb,
      mc: mc,
      md: md
    )
  end
end
