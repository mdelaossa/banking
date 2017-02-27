defmodule Bank.Institution.Example do
  @moduledoc """
  Example implementation of Bank.Institution, mostly for tests
  """

  use Bank.Institution, name: "Example Bank"

  alias Bank.Account
  alias Bank.Account.Transaction

  @spec accounts(Bank.Institution.t) :: [Account.t]
  def accounts(_bank) do
    [
      %Account{bank: __MODULE__, currency: :USD, type: :savings},
      %Account{bank: __MODULE__, currency: :NIO, type: :credit},
      %Account{bank: __MODULE__, currency: :USD, type: :credit},
      %Account{bank: __MODULE__, currency: :USD, type: :loan}
    ]
  end

  @spec transactions(Account.t, keyword()) :: Account.t
  def transactions(account, _opts \\ []) do
    datetime = %DateTime{calendar: Calendar.ISO, day: 18, hour: 22, microsecond: {278_138, 6},
                         minute: 49, month: 2, second: 4, std_offset: 0, time_zone: "Etc/UTC",
                         utc_offset: 0, year: 2017, zone_abbr: "UTC"}

    %Account{account | transactions: [
      %Transaction{value: 5000, payee: "Someone", datetime: datetime},
      %Transaction{value: 2500, payee: "Someone", debit: false, datetime: datetime},
      %Transaction{value: 1278, payee: "Someone else", datetime: datetime}
    ], balance: 3778}
  end
end
