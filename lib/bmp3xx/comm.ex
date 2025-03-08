# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  @bmp2_reg_chip_id 0xD0
  @bmp3_reg_chip_id 0x00

  @spec get_sensor_type(Transport.t()) :: {:ok, BMP3XX.sensor_type()} | {:error, any}
  def get_sensor_type(transport) do
    case get_bmp3_sensor_type(transport) do
      {:ok, bmp3_sensor_type} ->
        {:ok, bmp3_sensor_type}

      {:error, _error} ->
        get_bmp2_sensor_type(transport)
    end
  end

  defp get_bmp2_sensor_type(transport) do
    case Transport.write_read(transport, [@bmp2_reg_chip_id], 1) do
      {:ok, <<value>>} ->
        if bmp2_sensor_type(value) do
          {:ok, bmp2_sensor_type(value)}
        else
          {:error, "unsupported chip ID #{inspect(value, base: :hex)}"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_bmp3_sensor_type(transport) do
    case Transport.write_read(transport, [@bmp3_reg_chip_id], 1) do
      {:ok, <<value>>} ->
        if bmp3_sensor_type(value) do
          {:ok, bmp3_sensor_type(value)}
        else
          {:error, "unsupported chip ID #{inspect(value, base: :hex)}"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp bmp2_sensor_type(0x55), do: :bmp180
  defp bmp2_sensor_type(0x58), do: :bmp280
  defp bmp2_sensor_type(0x60), do: :bme280
  defp bmp2_sensor_type(0x61), do: :bme680
  defp bmp2_sensor_type(_), do: nil

  # https://github.com/boschsensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3_defs.h#LL130C3-L130C3
  defp bmp3_sensor_type(0x50), do: :bmp380
  defp bmp3_sensor_type(0x60), do: :bmp390
  defp bmp3_sensor_type(_), do: nil
end
