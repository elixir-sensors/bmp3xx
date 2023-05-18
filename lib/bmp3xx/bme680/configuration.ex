defmodule BMP3XX.BME680.Configuration do
  @moduledoc false

  alias BMP3XX.BME680.Calibration

  @doc """
  Convert the heater temperature into a register code.

  ## Examples

      iex> calibration = %{
      ...>   par_gh1: -30,
      ...>   par_gh2: -5969,
      ...>   par_gh3: 18,
      ...>   res_heat_val: 50,
      ...>   res_heat_range: 1,
      ...>   range_switching_error: 1
      ...> }
      iex> heater_resistance_code(300, 28, calibration)
      112
  """
  @spec heater_resistance_code(number, number, Calibration.t()) :: integer
  def heater_resistance_code(heater_temp_c, amb_temp_c, calibration) do
    %{
      par_gh1: par_gh1,
      par_gh2: par_gh2,
      par_gh3: par_gh3,
      res_heat_range: res_heat_range,
      res_heat_val: res_heat_val
    } = calibration

    var1 = par_gh1 / 16.0 + 49.0
    var2 = par_gh2 / 32_768.0 * 0.0005 + 0.00235
    var3 = par_gh3 / 1024.0
    var4 = var1 * (1.0 + var2 * heater_temp_c)
    var5 = var4 + var3 * amb_temp_c

    round(
      3.4 *
        (var5 * (4.0 / (4.0 + res_heat_range)) *
           (1.0 /
              (1.0 +
                 res_heat_val * 0.002)) - 25)
    )
  end

  @doc """
  Convert the heater duration milliseconds into a register code. Heating
  durations between 1 ms and 4032 ms can be configured. In practice,
  approximately 20-30 ms are necessary for the heater to reach the intended
  target temperature.

  ## Examples

      iex> heater_duration_code(63)
      63
      iex> heater_duration_code(64)
      80
      iex> heater_duration_code(100)
      89
      iex> heater_duration_code(4032)
      255
      iex> heater_duration_code(4033)
      ** (FunctionClauseError) no function clause matching in BMP3XX.BME680.Configuration.heater_duration_code/2
  """
  @spec heater_duration_code(1..4032, non_neg_integer) :: number
  def heater_duration_code(duration, factor \\ 0)

  def heater_duration_code(duration, factor) when duration in 64..4032 do
    duration |> div(4) |> heater_duration_code(factor + 1)
  end

  def heater_duration_code(duration, factor) when duration in 1..63 do
    duration + factor * 64
  end
end
