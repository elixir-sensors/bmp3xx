defmodule BMP3XX.BME280 do
  @moduledoc false

  alias BMP3XX.Transport

  defstruct transport: nil,
            calibration: nil,
            sea_level_pa: 0.0

  @type t() :: %__MODULE__{
          transport: Transport.t(),
          calibration: map(),
          sea_level_pa: float()
        }

  ## protocol implementation

  defimpl BMP3XX.Sensor do
    alias BMP3XX.BME280.Calibration
    alias BMP3XX.BME280.Comm
    alias BMP3XX.BME280.Measurement

    @impl BMP3XX.Sensor
    def init(%{transport: transport} = state, _options) do
      with :ok <- Comm.set_oversampling(transport),
           {:ok, raw_calibration} <- Comm.get_calibration(transport) do
        new_state = struct!(state, calibration: Calibration.from_raw(raw_calibration))
        {:ok, new_state}
      end
    end

    @impl BMP3XX.Sensor
    def measure(%{transport: transport} = state, _options) do
      %{calibration: calibration, sea_level_pa: sea_level_pa} = state

      case Comm.get_output(transport) do
        {:ok, raw_measurement} ->
          measurement = Measurement.from_raw(raw_measurement, calibration, sea_level_pa)
          {:ok, measurement}

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
