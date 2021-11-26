defmodule BMP3XX.Transport do
  @moduledoc false

  defstruct [:ref, :bus_address]

  @type t :: %__MODULE__{ref: reference(), bus_address: 0..127}
  @type option :: {:bus_name, String.t()} | {:bus_address, 0..127}

  @callback open([option()]) :: {:ok, t()} | {:error, any()}

  @callback read(t(), pos_integer()) :: {:ok, binary()} | {:error, any()}

  @callback write(t(), iodata()) :: :ok | {:error, any()}

  @callback write_read(t(), iodata(), pos_integer()) :: {:ok, binary()} | {:error, any()}
end

defmodule BMP3XX.Transport.I2C do
  @moduledoc false

  @behaviour BMP3XX.Transport

  @impl BMP3XX.Transport
  def open(opts) do
    bus_name = Access.fetch!(opts, :bus_name)
    bus_address = Access.fetch!(opts, :bus_address)

    case Circuits.I2C.open(bus_name) do
      {:ok, ref} ->
        {:ok, %BMP3XX.Transport{ref: ref, bus_address: bus_address}}

      _ ->
        :error
    end
  end

  @impl BMP3XX.Transport
  def read(transport, bytes_to_read) do
    Circuits.I2C.read(transport.ref, transport.bus_address, bytes_to_read)
  end

  @impl BMP3XX.Transport
  def write(transport, register_and_data) do
    Circuits.I2C.write(transport.ref, transport.bus_address, register_and_data)
  end

  @impl BMP3XX.Transport
  def write_read(transport, register, bytes_to_read) do
    Circuits.I2C.write_read(transport.ref, transport.bus_address, register, bytes_to_read)
  end
end

defmodule BMP3XX.Transport.Stub do
  @moduledoc false

  @behaviour BMP3XX.Transport

  @impl BMP3XX.Transport
  def open(_opts), do: {:ok, %BMP3XX.Transport{ref: make_ref(), bus_address: 0x00}}

  @impl BMP3XX.Transport
  def read(_transport, _bytes_to_read), do: {:ok, "stub"}

  @impl BMP3XX.Transport
  def write(_transport, _data), do: :ok

  @impl BMP3XX.Transport
  def write_read(_transport, _data, _bytes_to_read), do: {:ok, "stub"}
end
