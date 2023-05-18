defmodule BMP3XX.BME280.Comm do
  @moduledoc false

  alias BMP3XX.Transport

  # https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf
  @reg_calibration00 0x88
  @reg_calibration26 0xE1
  @reg_control_humidity 0xF2
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
    osrs_h = @oversampling_16x

    with :ok <- Transport.write(transport, [@reg_control_humidity, <<osrs_h>>]) do
      Transport.write(transport, [
        @reg_control_measurement,
        <<osrs_t::size(3), osrs_p::size(3), mode::size(2)>>
      ])
    end
  end

  @spec get_calibration(Transport.t()) :: {:ok, <<_::264>>} | {:error, any}
  def get_calibration(transport) do
    with {:ok, first_part} <- Transport.write_read(transport, [@reg_calibration00], 26),
         {:ok, second_part} <- Transport.write_read(transport, [@reg_calibration26], 7) do
      {:ok, first_part <> second_part}
    end
  end

  @spec get_output(Transport.t()) :: {:ok, <<_::64>>} | {:error, any}
  def get_output(transport) do
    Transport.write_read(transport, [@reg_measurement_data], 8)
  end
end
