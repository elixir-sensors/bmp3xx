defmodule BMP3XX.BMP388 do
  @moduledoc false

  alias BMP3XX.BMP388

  @behaviour BMP3XX.Sensor

  @impl BMP3XX.Sensor
  def init(%{transport: transport} = state) do
    with :ok <- BMP388.Comm.reset(transport),
         :ok <- BMP388.Comm.set_power_control_settings(transport),
         :ok <- BMP388.Comm.set_odr_and_filter_settings(transport),
         :ok <- BMP388.Comm.set_interrupt_control_settings(transport),
         :ok <- BMP388.Comm.set_serial_interface_settings(transport),
         {:ok, calibration_binary} <- BMP388.Comm.read_calibration(transport) do
      {:ok, %{state | calibration: BMP388.Calibration.from_binary(calibration_binary)}}
    end
  end

  @impl BMP3XX.Sensor
  def read(%{transport: transport, calibration: calibration, sea_level_pa: sea_level_pa} = _state) do
    case BMP388.Comm.read_raw_samples(transport) do
      {:ok, raw_samples} ->
        measurement = BMP388.Measurement.from_raw_samples(raw_samples, calibration, sea_level_pa)
        {:ok, measurement}

      error ->
        error
    end
  end
end
