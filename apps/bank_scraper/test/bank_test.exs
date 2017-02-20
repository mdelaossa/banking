defmodule BankTest do
  use ExUnit.Case

  @example_datetime %DateTime{calendar: Calendar.ISO, day: 18, hour: 22, microsecond: {278_138, 6},
                           minute: 49, month: 2, second: 4, std_offset: 0, time_zone: "Etc/UTC",
                           utc_offset: 0, year: 2017, zone_abbr: "UTC"}

  doctest Bank
end
