# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.Transport do
  @moduledoc false
  # Just a thin wrapper around the Circuits.I2C module for our convenience

  defstruct [:bus, :address, :options]

  @type address :: 0x76 | 0x77
  @type t :: %__MODULE__{bus: any, address: address, options: keyword}
  @type i2c_options :: [Circuits.I2C.opt()]

  @spec open(binary, address, i2c_options) :: {:error, any} | {:ok, t}
  def open(bus_name, address, options \\ []) do
    case Circuits.I2C.open(bus_name) do
      {:ok, bus} ->
        {:ok, __struct__(bus: bus, address: address, options: options)}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec read(t, pos_integer, i2c_options) :: {:error, any} | {:ok, binary}
  def read(%__MODULE__{} = t, count, options \\ []) do
    options = Enum.into(options, t.options)
    Circuits.I2C.read(t.bus, t.address, count, options)
  end

  @spec write(t, iodata, i2c_options) :: :ok | {:error, any}
  def write(%__MODULE__{} = t, data, options \\ []) do
    options = Enum.into(options, t.options)
    Circuits.I2C.write(t.bus, t.address, data, options)
  end

  @spec write_read(t, iodata, pos_integer, i2c_options) :: {:error, any} | {:ok, binary}
  def write_read(%__MODULE__{} = t, write_data, read_count, options \\ []) do
    options = Enum.into(options, t.options)
    Circuits.I2C.write_read(t.bus, t.address, write_data, read_count, options)
  end

  @spec close(t) :: :ok
  def close(%__MODULE__{} = t) do
    Circuits.I2C.close(t.bus)
  end
end
