defmodule BMP3XX.Measurement do
  @moduledoc """
  One sensor measurement report
  """

  defstruct [
    :altitude_m,
    :pressure_pa,
    :temperature_c,
    :timestamp_ms
  ]

  @type t :: %__MODULE__{
          altitude_m: number,
          pressure_pa: number,
          temperature_c: number,
          timestamp_ms: number
        }
end
