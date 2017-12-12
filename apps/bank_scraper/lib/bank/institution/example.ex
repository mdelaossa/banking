defmodule Bank.Institution.Example do
  @moduledoc """
  Example implementation of Bank.Institution, mostly for tests
  """

  use Bank.Institution, name: "Example Bank"

  alias Bank.Account
  alias Bank.Account.Transaction

  @lint {Credo.Check.Readability.Specs, false}
  def accounts(bank) do
    %Bank.Institution{bank | accounts: [
      {Kernel.make_ref, %Account{bank: __MODULE__, currency: :USD, type: :savings}},
      {Kernel.make_ref, %Account{bank: __MODULE__, currency: :NIO, type: :credit}},
      {Kernel.make_ref, %Account{bank: __MODULE__, currency: :USD, type: :credit}},
      {Kernel.make_ref, %Account{bank: __MODULE__, currency: :USD, type: :loan}}
    ]}
  end

  @spec accounts(Bank.Institution.t, atom) :: Bank.Institution.t
  def accounts(bank, type) do
    with accounts <- accounts(bank),
         filtered_accounts <- Enum.filter(accounts, fn(acc) -> elem(acc, 1).type == type end),
    do: %{bank | accounts: filtered_accounts}
  end

  @spec transactions(Bank.Institution.t, reference, keyword) :: Bank.Institution.t
  def transactions(bank, ref, _opts \\ []) do
    with datetime <- %DateTime{calendar: Calendar.ISO, day: 18, hour: 22, microsecond: {278_138, 6},
                               minute: 49, month: 2, second: 4, std_offset: 0, time_zone: "Etc/UTC",
                               utc_offset: 0, year: 2017, zone_abbr: "UTC"},
         {{^ref, account}, accounts} <- bank |> Map.get(:accounts) |> List.keytake(ref, 0),
         account <- %{account | transactions: [
                       %Transaction{value: 5000, payee: "Someone", datetime: datetime},
                       %Transaction{value: 2500, payee: "Someone", debit: false, datetime: datetime},
                       %Transaction{value: 1278, payee: "Someone else", datetime: datetime}
                       ], balance: 3778},
         accounts <- accounts |> List.keystore(ref, 0, {ref, account}),
    do: %{bank | accounts: accounts}
  end
end
