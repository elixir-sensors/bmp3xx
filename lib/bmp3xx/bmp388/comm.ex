defmodule BMP3XX.BMP388.Comm do
  @moduledoc false

  # https://github.com/BoschSensortec/BMP3-Sensor-API/blob/5c13e49e7649099696ff6ca5f5fe3ad4ab3f5d96/bmp3_defs.h#L142
  @reg_data 0x04
  @reg_int_ctrl 0x19
  @reg_calib_data 0x31
  @reg_if_conf 0x1A
  @reg_pwr_ctrl 0x1B
  @reg_osr 0x1C
  @reg_odr 0x1D
  @reg_config 0x1F
  @reg_cmd 0x7E

  # @fifo_subsampling_2x 0x01
  # @fifo_subsampling_4x 0x02
  # @fifo_subsampling_8x 0x03
  # @fifo_subsampling_16x 0x04
  # @fifo_subsampling_32x 0x05
  # @fifo_subsampling_64x 0x06
  # @fifo_subsampling_128x 0x07

  @oversampling_2x 0x01
  # @oversampling_4x 0x02
  # @oversampling_8x 0x03
  @oversampling_16x 0x04
  # @oversampling_32x 0x05

  # @iir_filter_coeff_1 0x01
  @iir_filter_coeff_3 0x02
  # @iir_filter_coeff_7 0x03
  # @iir_filter_coeff_15 0x04
  # @iir_filter_coeff_31 0x05
  # @iir_filter_coeff_63 0x06
  # @iir_filter_coeff_127 0x07

  # @odr_200_hz 0x00
  # @odr_100_hz 0x01
  # @odr_50_hz 0x02
  @odr_25_hz 0x03
  # @odr_12_5_hz 0x04
  # @odr_6_25_hz 0x05
  # @odr_3_1_hz 0x06
  # @odr_1_5_hz 0x07
  # @odr_0_78_hz 0x08
  # @odr_0_39_hz 0x09
  # @odr_0_2_hz 0x0A
  # @odr_0_1_hz 0x0B
  # @odr_0_05_hz 0x0C
  # @odr_0_02_hz 0x0D
  # @odr_0_01_hz 0x0E
  # @odr_0_006_hz 0x0F
  # @odr_0_003_hz 0x10
  # @odr_0_001_hz 0x11

  # @mode_sleep 0x00
  # @mode_forced 0x01
  @mode_normal 0x03
  @int_level_active_high 0x01
  # @i2c_wdt_short_1_25_ms 0x00
  @i2c_wdt_long_40_ms 0x01

  @spec reset(BMP3XX.Transport.t()) :: :ok | {:error, any()}
  def reset(transport) do
    with :ok <- transport_mod().write(transport, [@reg_cmd, <<0xB6>>]),
         :ok <- Process.sleep(10),
         do: :ok
  end

  @doc """
  Set the power control(pressure enable and temperature enable).
  """
  @spec set_power_control_settings(BMP3XX.Transport.t()) :: :ok | {:error, any()}
  def set_power_control_settings(transport) do
    mode = @mode_normal
    temp_en = 1
    press_en = 1

    transport_mod().write(transport, [
      @reg_pwr_ctrl,
      <<0::2, mode::2, 0::2, temp_en::1, press_en::1>>
    ])
  end

  @doc """
  Set the over sampling, ODR (output data rate or sampling rate) and filter settings.
  """
  @spec set_odr_and_filter_settings(BMP3XX.Transport.t()) :: :ok | {:error, any()}
  def set_odr_and_filter_settings(transport) do
    osr_t = @oversampling_2x
    osr_p = @oversampling_16x
    odr_sel = @odr_25_hz
    iir_filter = @iir_filter_coeff_3

    with :ok <- transport_mod().write(transport, [@reg_osr, <<0::2, osr_t::3, osr_p::3>>]),
         :ok <- transport_mod().write(transport, [@reg_odr, <<0::3, odr_sel::5>>]) do
      transport_mod().write(transport, [@reg_config, <<0::4, iir_filter::3, 0::1>>])
    end
  end

  @doc """
  Set the interrupt control (output mode, level, latch and data ready) settings of the sensor
  based on the settings selected by the user.
  """
  @spec set_interrupt_control_settings(BMP3XX.Transport.t()) :: :ok | {:error, any()}
  def set_interrupt_control_settings(transport) do
    drdy_en = 0
    ffull_en = 0
    fwtm_en = 0
    int_latch = 0
    int_level = @int_level_active_high
    int_od = 0

    transport_mod().write(transport, [
      @reg_int_ctrl,
      <<0::1, drdy_en::1, 0::1, ffull_en::1, fwtm_en::1, int_latch::1, int_level::1, int_od::1>>
    ])
  end

  @doc """
  Set the serial interface settings.
  """
  @spec set_serial_interface_settings(BMP3XX.Transport.t()) :: :ok | {:error, any()}
  def set_serial_interface_settings(transport) do
    i2c_wdt_sel = @i2c_wdt_long_40_ms
    i2c_wdt_en = 1
    spi3 = 0

    transport_mod().write(transport, [
      @reg_if_conf,
      <<0::5, i2c_wdt_sel::1, i2c_wdt_en::1, spi3::1>>
    ])
  end

  @spec read_calibration(BMP3XX.Transport.t()) :: {:ok, <<_::168>>} | {:error, any()}
  def read_calibration(transport) do
    transport_mod().write_read(transport, [@reg_calib_data], 21)
  end

  @spec read_raw_samples(BMP3XX.Transport.t()) :: {:error, any()} | {:ok, <<_::48>>}
  def read_raw_samples(transport) do
    transport_mod().write_read(transport, [@reg_data], 6)
  end

  defp transport_mod() do
    Application.get_env(:bmp3xx, :transport_mod, BMP3XX.Transport.I2C)
  end
end
