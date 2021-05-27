defmodule BMP3XX.CalcTest do
  use ExUnit.Case, async: true
  alias BMP3XX.Calc
  doctest BMP3XX.Calc

  test "altitude calculation" do
    sea_level_pa = 101_325
    current_pa = 100_736.516
    altitude = 49.109577

    assert_in_delta altitude, Calc.pressure_to_altitude(current_pa, sea_level_pa), 0.001
    assert_in_delta sea_level_pa, Calc.sea_level_pressure(current_pa, altitude), 0.001
  end

  test "dew point calculation" do
    assert_in_delta 14.87, Calc.dew_point(64, 22), 0.01
  end
end
