# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BMP280.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  # https://cdn-shop.adafruit.com/datasheets/BST-BMP280-DS001-11.pdf
  @reg_calibration 0x88
  @reg_control_measurement 0xF4
  @reg_measurement_data 0xF7

  @oversampling_2x 2
  @oversampling_16x 5
  @normal_mode 3

  @spec set_oversampling(Transport.t()) :: :ok | {:error, any}
  def set_oversampling(transport) do
    mode = @normal_mode
    osrs_t = @oversampling_2x
    osrs_p = @oversampling_16x
    data = <<osrs_t::3, osrs_p::3, mode::2>>

    Transport.write(transport, [@reg_control_measurement, data])
  end

  @spec get_calibration(Transport.t()) :: {:ok, <<_::192>>} | {:error, any}
  def get_calibration(transport) do
    Transport.write_read(transport, [@reg_calibration], 24)
  end

  @spec get_output(Transport.t()) :: {:ok, <<_::48>>} | {:error, any}
  def get_output(transport) do
    Transport.write_read(transport, [@reg_measurement_data], 6)
  end
end
