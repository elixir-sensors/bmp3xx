defmodule BMP3XX.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  # https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3_defs.h#L142
  @bmp3_reg_chip_id 0x00

  @spec sensor_type(Transport.t()) :: {:ok, BMP3XX.bus_address()} | {:error, any}
  def sensor_type(transport) do
    case Transport.I2C.write_read(transport, @bmp3_reg_chip_id, 1) do
      {:ok, <<0x50>>} -> {:ok, :bmp388}
      {:ok, <<0x60>>} -> {:ok, :bmp390}
      {:ok, _} -> {:error, "Unsupported chip ID"}
      error -> error
    end
  end
end
