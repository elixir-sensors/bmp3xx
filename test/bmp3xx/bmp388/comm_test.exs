defmodule BMP3XX.BMP388.CommTest do
  use ExUnit.Case, async: true
  alias BMP3XX.BMP388.Comm

  # https://hexdocs.pm/mox/Mox.html
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "read_calibration" do
    BMP3XX.MockI2C
    |> Mox.expect(:write_read, 1, fn _, 0x31, 21 ->
      {:ok, <<0x236B5849F65CFFCEF42300EA636E79F3F6AA4312C4::168>>}
    end)

    assert {:ok, <<_::168>>} = Comm.read_calibration(transport())
  end

  test "read_raw_samples" do
    BMP3XX.MockI2C
    |> Mox.expect(:write_read, 1, fn _, 0x04, 6 ->
      {:ok, <<0x979F6D73D885::48>>}
    end)

    assert {:ok, <<_::48>>} = Comm.read_raw_samples(transport())
  end

  defp transport, do: :c.pid(0, 0, 0)
end
