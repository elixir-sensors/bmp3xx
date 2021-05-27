defmodule BMP3XX.Transport.I2C.Stub do
  @moduledoc false

  @behaviour BMP3XX.Transport

  @impl BMP3XX.Transport
  def start_link(_opts) do
    {:ok, :c.pid(0, 0, 0)}
  end

  @impl BMP3XX.Transport
  def read(_transport, _bytes_to_read) do
    {:ok, "stub"}
  end

  @impl BMP3XX.Transport
  def write(_transport, _register_and_data) do
    :ok
  end

  @impl BMP3XX.Transport
  def write(_transport, _register, _data) do
    :ok
  end

  @impl BMP3XX.Transport
  def write_read(_transport, _register, _bytes_to_read) do
    {:ok, "stub"}
  end
end
