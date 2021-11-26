defmodule BMP3XX.Comm do
  @moduledoc false

  # https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3_defs.h#L142
  @bmp3_reg_chip_id 0x00

  @spec sensor_type(BMP3XX.Transport.t()) :: {:ok, atom()} | {:error, any()}
  def sensor_type(transport) do
    case transport_mod().write_read(transport, [@bmp3_reg_chip_id], 1) do
      {:ok, <<0x50>>} -> {:ok, BMP3XX.BMP388}
      {:ok, <<0x60>>} -> {:ok, BMP3XX.BMP390}
      {:ok, _} -> {:error, "Unsupported chip ID"}
      error -> error
    end
  end

  defp transport_mod() do
    Application.get_env(:bmp3xx, :transport_mod, BMP3XX.Transport.I2C)
  end
end
