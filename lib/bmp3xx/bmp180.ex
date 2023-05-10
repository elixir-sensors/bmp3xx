defmodule BMP3XX.BMP180 do
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
    alias BMP3XX.BMP180.Calibration
    alias BMP3XX.BMP180.Comm
    alias BMP3XX.BMP180.Measurement

    @impl BMP3XX.Sensor
    def init(%{transport: transport} = state, _options) do
      case Comm.get_calibration(transport) do
        {:ok, raw_calibration} ->
          new_state = struct!(state, calibration: Calibration.from_raw(raw_calibration))
          {:ok, new_state}

        {:error, error} ->
          {:error, error}
      end
    end

    @impl BMP3XX.Sensor
    def measure(%{transport: transport} = state, _options) do
      %{calibration: calibration, sea_level_pa: sea_level_pa} = state

      case Comm.get_output(transport) do
        {:ok, {raw_t, raw_p}} ->
          measurement = Measurement.from_raw(raw_t, raw_p, calibration, sea_level_pa)
          {:ok, measurement}

        {:error, error} ->
          {:error, error}
      end
    end
  end
end
