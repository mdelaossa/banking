defmodule Bank do
  @moduledoc """
  Convenience module to get and use specific Bank scrapers.
  """

  @doc """
  Returns a specific Bank.Institution

  ## Examples

      iex> Bank.find_institution("Example")
      {:ok, %Bank.Institution{bank: Bank.Institution.Example, name: "Example Bank", accounts: []}}

      iex> Bank.find_institution(Example)
      {:ok, %Bank.Institution{bank: Bank.Institution.Example, name: "Example Bank", accounts: []}}

      iex> Bank.find_institution(DoesNotExist)
      {:error, "No Institution defined by that module name"}

  """
  @spec find_institution(String.t | atom) :: {:ok, Bank.Institution.t} | {:error, any}
  def find_institution(name) when is_nil(name), do: {:error, "Name must be binary or atom"}
  def find_institution(name) when is_binary(name) or is_atom(name) do
    Bank.Institution
    |> Module.concat(name)
    |> check_institution_exists
  end
  def find_institution(_), do: {:error, "Name must be binary or atom"}

  @spec find_institution!(String.t | atom) :: Bank.Institution.t
  def find_institution!(name) when is_binary(name) or is_atom(name) do
    case find_institution(name) do
      {:ok, institution} -> institution
      {:error, error} -> raise error
    end
  end

  @doc """
  Populates the `accounts` of the given Bank.Institution struct

  ## Examples

      ...> Bank.find_institution!(Example) |> Bank.fetch_accounts
      {:ok, %Bank.Institution{
        bank: Bank.Institution.Example,
        name: "Example Bank",
        accounts: [{Reference<>, %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :savings}},
                   {Reference<>, %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :NIO, type: :credit}},
                   {Reference<>, %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :credit}},
                   {Reference<>, %Bank.Account{bank: Bank.Institution.Example, balance: 0, currency: :USD, type: :loan}}]
      }}

  """
  @spec fetch_accounts(Bank.Institution.t) :: {:ok, Bank.Institution.t}
  def fetch_accounts(%Bank.Institution{bank: bank} = struct) do
    {:ok, bank.accounts(struct)}
  end

  @spec fetch_accounts!(Bank.Institution.t) :: [Bank.Account.t]
  def fetch_accounts!(%Bank.Institution{bank: bank} = struct) do
    bank.accounts struct
  end

  @doc """
  Takes the account referenced by 'reference' out of the Bank.Institution object
  """
  @spec get_account(Bank.Institution.t, reference) :: {:ok, Bank.Account.t}
  def get_account(%Bank.Institution{accounts: accounts}, ref) when is_reference(ref) do
    accounts
    |> List.keytake(ref, 0)
    |> elem(0)
    |> elem(1)
  end

  @doc """
  Fetches all transactions that match the given options for a `Bank.Account`.

  Valid options are:

    - start_date (DateTime)
    - end_date (DateTime)
    - type: (List[atom]) - Will filter by type given

  ## Examples

      ...> bank = Bank.find_institution!(Example) |> Bank.fetch_accounts!
      ...> [account | _] = bank.accounts
      ...> Bank.fetch_transactions(bank, elem(account,0))
      {:ok, %Bank.Institution{accounts: [%Bank.Account{bank: Bank.Institution.Example, type: :savings, currency: :USD, balance: 3778,
        transactions: [
          %Bank.Account.Transaction{value: 5000, payee: "Someone", datetime: @example_datetime},
          %Bank.Account.Transaction{value: 2500, payee: "Someone", debit: false, datetime: @example_datetime},
          %Bank.Account.Transaction{value: 1278, payee: "Someone else", datetime: @example_datetime}
        ]
      }]}}

  """
  @spec fetch_transactions(Bank.Institution.t, reference, keyword) :: {:ok, Bank.Institution.t}
  def fetch_transactions(%Bank.Institution{bank: bank} = struct, ref, opts \\ []) do
    {:ok, bank.transactions(struct, ref, opts)}
  end

  defp check_institution_exists(institution) do
    with attributes <- institution.__info__(:attributes),
         behaviours <- Keyword.get(attributes, :behaviour),
         true <- Enum.member?(behaviours, Bank.Institution),
         institution <- institution.init([])
    do {:ok, institution}
    else _ -> {:error, "No Institution defined by that module name"}
    end
  rescue
    UndefinedFunctionError -> {:error, "No Institution defined by that module name"}
  end
end
