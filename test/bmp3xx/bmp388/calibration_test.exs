# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.BMP380.CalibrationTest do
  use ExUnit.Case, async: true

  alias BMP3XX.BMP380.Calibration
  alias BMP3XX.BMP380.Measurement

  test "from_raw" do
    result = Calibration.from_raw(<<0x236B5849F65CFFCEF42300EA636E79F3F6AA4312C4::168>>)

    assert %Calibration{
             par_t1: 27_427,
             par_t2: 18_776,
             par_t3: -10,
             par_p1: -164,
             par_p2: -2866,
             par_p3: 35,
             par_p4: 0,
             par_p5: 25_578,
             par_p6: 31_086,
             par_p7: -13,
             par_p8: -10,
             par_p9: 17_322,
             par_p10: 18,
             par_p11: -60
           } == result
  end

  test "raw_to_pressure_pa_and_temperature_c" do
    calibration = %Calibration{
      par_t1: 27_427,
      par_t2: 18_776,
      par_t3: -10,
      par_p1: -164,
      par_p2: -2866,
      par_p3: 35,
      par_p4: 0,
      par_p5: 25_578,
      par_p6: 31_086,
      par_p7: -13,
      par_p8: -10,
      par_p9: 17_322,
      par_p10: 18,
      par_p11: -60
    }

    result =
      Measurement.pressure_pa_and_temperature_c_from_raw(<<0x979F6D73D885::48>>, calibration)

    assert_in_delta 100_876.00634692199, elem(result, 0), 0.0001
    assert_in_delta 30.499314453874284, elem(result, 1), 0.0001
  end
end
