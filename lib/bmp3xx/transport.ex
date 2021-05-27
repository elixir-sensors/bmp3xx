defmodule BMP3XX.Transport do
  @moduledoc false

  @type t :: pid
  @type bus_name :: binary
  @type bus_address :: 0..127
  @type register :: non_neg_integer()

  @callback start_link(bus_name: bus_name, bus_address: bus_address) ::
              {:ok, t} | {:error, any}

  @callback read(t, integer) ::
              {:ok, binary} | {:error, any}

  @callback write(t, iodata) ::
              :ok | {:error, any}

  @callback write(t, register, iodata) ::
              :ok | {:error, any}

  @callback write_read(t, register, integer) ::
              {:ok, binary} | {:error, any}
end
