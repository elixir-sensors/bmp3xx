# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BMP180.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  # https://cdn-shop.adafruit.com/datasheets/BST-BMP180-DS000-09.pdf
  @reg_calibration 0xAA
  @reg_control_measurement 0xF4
  @reg_measurement_data 0xF6

  @spec get_calibration(Transport.t()) :: {:ok, <<_::176>>} | {:error, any()}
  def get_calibration(transport) do
    Transport.write_read(transport, [@reg_calibration], 22)
  end

  @spec get_output(Transport.t()) :: {:ok, {<<_::24>>, <<_::24>>}} | {:error, any()}
  def get_output(transport) do
    with {:ok, raw_temperature} <- get_temperature(transport),
         {:ok, raw_pressure} <- get_pressure(transport) do
      {:ok, {raw_temperature, raw_pressure}}
    end
  end

  defp get_temperature(transport) do
    with :ok <- Transport.write(transport, [@reg_control_measurement, <<0x2E>>]),
         :ok <- Process.sleep(10) do
      Transport.write_read(transport, [@reg_measurement_data], 3)
    end
  end

  defp get_pressure(transport) do
    with :ok <- Transport.write(transport, [@reg_control_measurement, <<0x34>>]),
         :ok <- Process.sleep(10) do
      Transport.write_read(transport, [@reg_measurement_data], 3)
    end
  end
end
