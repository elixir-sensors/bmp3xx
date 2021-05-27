defmodule BMP3XX.BMP388.MeasurementTest do
  use ExUnit.Case, async: true
  alias BMP3XX.BMP388.Measurement

  @calibration %{
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

  test "from_raw_samples" do
    result =
      <<151, 159, 109, 115, 216, 133>>
      |> Measurement.from_raw_samples(@calibration)
      |> Measurement.put_altitude_m(101_913.14)

    assert %BMP3XX.Measurement{
             altitude_m: 86.2037596584836,
             pressure_pa: 100_876.00634692199,
             temperature_c: 30.499314453874284,
             timestamp_ms: _
           } = result
  end
end
