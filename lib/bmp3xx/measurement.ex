# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BMP3XX.Measurement do
  @moduledoc """
  One sensor measurement report
  """

  defstruct [
    :altitude_m,
    :pressure_pa,
    :timestamp_ms,
    dew_point_c: :unknown,
    gas_resistance_ohms: :unknown,
    humidity_rh: :unknown,
    temperature_c: :unknown
  ]

  @type t :: %__MODULE__{
          altitude_m: number,
          pressure_pa: number,
          timestamp_ms: integer,
          dew_point_c: number | :unknown,
          gas_resistance_ohms: number | :unknown,
          humidity_rh: number | :unknown,
          temperature_c: number | :unknown
        }
end
