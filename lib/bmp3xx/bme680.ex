defmodule BMP3XX.BME680 do
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
    alias BMP3XX.BME680.Calibration
    alias BMP3XX.BME680.Comm
    alias BMP3XX.BME680.Configuration
    alias BMP3XX.BME680.Measurement

    @heater_temperature_c 300
    @heater_duration_ms 100
    @ambient_temperature_c 25

    @impl BMP3XX.Sensor
    def init(%{transport: transport} = state, _options) do
      with :ok <- Comm.reset(transport),
           {:ok, raw_calibration} <- Comm.get_calibration(transport),
           calibration <- Calibration.from_raw(raw_calibration),
           :ok <- Comm.set_oversampling(transport),
           :ok <- Comm.set_filter(transport),
           :ok <- Comm.enable_gas_sensor(transport),
           :ok <-
             Comm.set_gas_heater_temperature(
               transport,
               Configuration.heater_resistance_code(
                 @heater_temperature_c,
                 @ambient_temperature_c,
                 calibration
               )
             ),
           :ok <-
             Comm.set_gas_heater_duration(
               transport,
               Configuration.heater_duration_code(@heater_duration_ms)
             ),
           :ok <- Comm.set_gas_heater_profile(transport, 0) do
        new_state = struct!(state, calibration: calibration)
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
