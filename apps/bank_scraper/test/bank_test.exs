defmodule BankTest do
  use ExUnit.Case, async: true

  @example_datetime %DateTime{calendar: Calendar.ISO, day: 18, hour: 22, microsecond: {278_138, 6},
                           minute: 49, month: 2, second: 4, std_offset: 0, time_zone: "Etc/UTC",
                           utc_offset: 0, year: 2017, zone_abbr: "UTC"}

  test "find_institution/1 returns a Bank.Institution if it exists" do
    assert {:ok, %Bank.Institution{bank: Bank.Institution.Example}} = Bank.find_institution("Example")
  end

  test "find_institution/1 accepts an atom" do
    assert {:ok, %Bank.Institution{bank: Bank.Institution.Example}} = Bank.find_institution(Example)
  end

  test "find_institution/1 returns an :error tuple if the Institution does not exist" do
    assert {:error, "No Institution defined by that module name"} == Bank.find_institution(DoesNotExist)
  end

  test "fetch_accounts/1 populates the accounts of a Bank.Institution" do
    {:ok, %Bank.Institution{} = bank} = Example |> Bank.find_institution! |> Bank.fetch_accounts

    # The first element of each Account tuple should be a Reference
    assert true == Enum.reduce(bank.accounts, true, fn(acc, result) -> result && is_reference(elem(acc,0)) end)

    accounts = bank.accounts
      |> Enum.map(fn(tuple) -> elem(tuple, 1) end)

    assert [%Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :savings},
            %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :NIO, type: :credit},
            %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :credit},
            %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :loan}] == accounts

  end

  test "fetch_transactions/3 populates the Transactions of a Bank.Account inside a Bank.Institution" do
    with {:ok, %Bank.Institution{} = bank} <- Example |> Bank.find_institution! |> Bank.fetch_accounts,
         [{account_ref, _} | _] = bank.accounts,
         {:ok, bank} <- Bank.fetch_transactions(bank, account_ref),
         account <- Bank.get_account(bank, account_ref)
    do
      assert %Bank.Account{bank: Bank.Institution.Example, type: :savings, currency: :USD, balance: 3778,
              transactions: [
                %Bank.Account.Transaction{value: 5000, payee: "Someone", datetime: @example_datetime},
                %Bank.Account.Transaction{value: 2500, payee: "Someone", debit: false, datetime: @example_datetime},
                %Bank.Account.Transaction{value: 1278, payee: "Someone else", datetime: @example_datetime}
              ]
            } == account
    end
  end
end
