defmodule BMP3XX.BMP390 do
  @moduledoc false

  @behaviour BMP3XX.Sensor

  @impl BMP3XX.Sensor
  defdelegate init(state), to: BMP3XX.BMP388

  @impl BMP3XX.Sensor
  defdelegate read(state), to: BMP3XX.BMP388
end
