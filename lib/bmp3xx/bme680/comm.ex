# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BME680.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  @reg_coeff1 0x8A
  @reg_coeff2 0xE1
  @reg_coeff3 0x00
  @reg_config 0x75
  @reg_ctrl_gas1 0x71
  @reg_ctrl_hum 0x72
  @reg_ctrl_meas 0x74
  @reg_gas_r_msb 0x2A
  @reg_gas_wait0 0x64
  @reg_meas_status0 0x1D
  @reg_press_msb 0x1F
  @reg_res_heat0 0x5A
  @reg_reset 0xE0

  @oversampling_2x 2
  @oversampling_16x 5

  @sleep_mode 0
  @forced_mode 1

  @filter_size_3 2

  @doc """
  Reset the sensor
  """
  @spec reset(Transport.t()) :: :ok | {:error, any}
  def reset(transport) do
    case Transport.write(transport, [@reg_reset, <<0xB6>>]) do
      :ok ->
        Process.sleep(10)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec set_sleep_mode(Transport.t()) :: :ok | {:error, any}
  def set_sleep_mode(transport), do: set_power_mode(transport, @sleep_mode)

  @spec set_forced_mode(Transport.t()) :: :ok | {:error, any}
  def set_forced_mode(transport), do: set_power_mode(transport, @forced_mode)

  defp set_power_mode(transport, mode) do
    case Transport.write_read(transport, [@reg_ctrl_meas], 1) do
      {:ok, <<reserved::6, _mode::2>>} ->
        Transport.write(transport, [@reg_ctrl_meas, <<reserved::6, mode::2>>])

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Set humidity oversampling, temperature oversampling and pressure oversampling to default values.
  """
  @spec set_oversampling(Transport.t()) :: :ok | {:error, any}
  def set_oversampling(transport) do
    mode = @sleep_mode
    osrs_h = @oversampling_16x
    osrs_t = @oversampling_2x
    osrs_p = @oversampling_16x

    case Transport.write(transport, [@reg_ctrl_hum, <<osrs_h>>]) do
      :ok ->
        Transport.write(transport, [@reg_ctrl_meas, <<osrs_t::3, osrs_p::3, mode::2>>])

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Set IIR filter size.
  """
  @spec set_filter(Transport.t()) :: :ok | {:error, any}
  def set_filter(transport) do
    case Transport.write_read(transport, [@reg_config], 1) do
      {:ok, <<reserved1::3, _filter::3, reserved2::2>>} ->
        Transport.write(transport, [
          @reg_config,
          <<reserved1::3, @filter_size_3::3, reserved2::2>>
        ])

      {:error, error} ->
        {:error, error}
    end
  end

  @spec enable_gas_sensor(Transport.t()) :: :ok | {:error, any}
  def enable_gas_sensor(transport), do: set_gas_status(transport, 1)

  @spec disable_gas_sensor(Transport.t()) :: :ok | {:error, any}
  def disable_gas_sensor(transport), do: set_gas_status(transport, 0)

  defp set_gas_status(transport, run_gas) do
    case Transport.write_read(transport, [@reg_ctrl_gas1], 1) do
      {:ok, <<reserved1::3, _run_gas::1, reserved2::4>>} ->
        Transport.write(transport, [@reg_ctrl_gas1, <<reserved1::3, run_gas::1, reserved2::4>>])

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Set gas sensor heater temperature in register code.
  """
  @spec set_gas_heater_temperature(Transport.t(), number, 0..9) :: :ok | {:error, any}
  def set_gas_heater_temperature(transport, heater_resistance, heater_set_point \\ 0) do
    Transport.write(transport, [@reg_res_heat0 + heater_set_point, <<heater_resistance>>])
  end

  @doc """
  Set gas sensor heater dutation in register code.
  """
  @spec set_gas_heater_duration(Transport.t(), number, 0..9) :: :ok | {:error, any}
  def set_gas_heater_duration(transport, heater_duration, heater_set_point \\ 0) do
    Transport.write(transport, [@reg_gas_wait0 + heater_set_point, <<heater_duration>>])
  end

  @doc """
  Set gas sensor conversion profile.
  """
  @spec set_gas_heater_profile(Transport.t(), 0..9) :: :ok | {:error, any}
  def set_gas_heater_profile(transport, heater_set_point) do
    case Transport.write_read(transport, [@reg_ctrl_gas1], 1) do
      {:ok, <<reserved::4, _heater_set_point::4>>} ->
        Transport.write(transport, [@reg_ctrl_gas1, <<reserved::4, heater_set_point::4>>])

      {:error, error} ->
        {:error, error}
    end
  end

  @spec get_calibration(Transport.t()) :: {:ok, <<_::336>>} | {:error, any}
  def get_calibration(transport) do
    with {:ok, coeff_block1} <- Transport.write_read(transport, [@reg_coeff1], 23),
         {:ok, coeff_block2} <- Transport.write_read(transport, [@reg_coeff2], 14),
         {:ok, coeff_block3} <- Transport.write_read(transport, [@reg_coeff3], 5) do
      {:ok, coeff_block1 <> coeff_block2 <> coeff_block3}
    end
  end

  @spec get_output(Transport.t()) :: {:error, any} | {:ok, <<_::80>>}
  def get_output(transport) do
    with :ok <- set_forced_mode(transport),
         :ok <- ensure_new_data(transport),
         {:ok, pth_block} <- Transport.write_read(transport, [@reg_press_msb], 8),
         {:ok, gas_block} <- Transport.write_read(transport, [@reg_gas_r_msb], 2) do
      {:ok, pth_block <> gas_block}
    end
  end

  defp ensure_new_data(transport) do
    if new_data?(transport) do
      :ok
    else
      {:error, :data_not_ready}
    end
  end

  def new_data?(transport) do
    case Transport.write_read(transport, [@reg_meas_status0], 1) do
      {:ok, <<new_data0::1, _gas_measuring::1, _measuring::1, _::1, _gas_meas_index0::4>>} ->
        new_data0 == 1

      {:error, error} ->
        {:error, error}
    end
  end
end
