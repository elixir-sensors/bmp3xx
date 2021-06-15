defmodule BMP3XX.Transport.I2C do
  @moduledoc false

  @behaviour BMP3XX.Transport

  @impl BMP3XX.Transport
  def start_link(opts) do
    transport_module().start_link(opts)
  end

  @impl BMP3XX.Transport
  def read(transport, bytes_to_read) do
    transport_module().read(transport, bytes_to_read)
  end

  @impl BMP3XX.Transport
  def write(transport, register_and_data) do
    transport_module().write(transport, register_and_data)
  end

  @impl BMP3XX.Transport
  def write(transport, register, data) do
    transport_module().write(transport, register, data)
  end

  @impl BMP3XX.Transport
  def write_read(transport, register, bytes_to_read) do
    transport_module().write_read(transport, register, bytes_to_read)
  end

  defp transport_module() do
    Application.get_env(:bmp3xx, :transport_module, I2cServer)
  end
end
