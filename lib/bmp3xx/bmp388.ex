defmodule BMP3XX.BMP388 do
  @moduledoc false

  alias BMP3XX.BMP388.{Calibration, Comm, Measurement}

  @behaviour BMP3XX.Sensor

  @impl true
  def init(%{transport: transport} = state) do
    with :ok <- Comm.reset(transport),
         :ok <- Comm.set_power_control_settings(transport),
         :ok <- Comm.set_odr_and_filter_settings(transport),
         :ok <- Comm.set_interrupt_control_settings(transport),
         :ok <- Comm.set_serial_interface_settings(transport),
         {:ok, calibration_binary} <- Comm.read_calibration(transport) do
      %{state | calibration: Calibration.from_binary(calibration_binary)}
    else
      _error -> raise "Error initializing BMP388 sensor"
    end
  end

  @impl true
  def read(%{transport: transport, calibration: calibration, sea_level_pa: sea_level_pa} = _state) do
    case Comm.read_raw_samples(transport) do
      {:ok, raw_samples} ->
        measurement =
          raw_samples
          |> Measurement.from_raw_samples(calibration)
          |> Measurement.put_altitude_m(sea_level_pa)

        {:ok, measurement}

      error ->
        error
    end
  end
end
