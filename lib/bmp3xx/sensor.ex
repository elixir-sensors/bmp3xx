defprotocol BMP3XX.Sensor do
  @moduledoc false
  # A protocol for BMP3XX sensors.

  @doc """
  Initialize a sensor.
  """
  @spec init(t(), options :: keyword) :: {:ok, t()} | {:error, any}
  def init(dev, options \\ [])

  @doc """
  Read output data from a sensor.
  """
  @spec measure(t(), options :: keyword) :: {:ok, map} | {:error, any}
  def measure(dev, options \\ [])
end
