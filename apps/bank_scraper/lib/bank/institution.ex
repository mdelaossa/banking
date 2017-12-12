defmodule Bank.Institution do
  @moduledoc """
  Defines the Bank Institution behaviour
  """

  @type t :: %__MODULE__{
                bank: atom,
                name: binary,
                accounts: [{reference, Bank.Account.t}],
                credentials: keyword
                }

  @enforce_keys [:bank, :name]
  defstruct bank: nil, name: nil, accounts: [], credentials: []

  defmacro __using__(opts) do
    unless opts[:name] != nil, do: raise ArgumentError, message: ":name option is required when `use`ing Bank.Institution"

    quote bind_quoted: [opts: opts] do
      @behaviour Bank.Institution

      @name opts[:name]

      @spec init(keyword) :: Bank.Institution.t
      def init(credentials), do: %Bank.Institution{bank: __MODULE__, name: @name, credentials: credentials}

      @spec accounts(Bank.Institution.t) :: Bank.Institution.t | {:error, atom, any}
      def accounts(%Bank.Institution{} = bank), do: accounts(bank, :all)

      defoverridable [init: 1, accounts: 1]
    end
  end

  @doc """
  Returns a `Bank.Institution` struct with information required to perform further actions.
  The implementing module must ensure to add itself as the `bank` keyword
  """
  @callback init(credentials :: keyword) :: Bank.Institution.t

  @doc """
  Fills out a `Bank.Institution`'s 'accounts' key with `Bank.Account` objects belonging to a bank.
  The implementing module must ensure to add itself as the 'bank' keyword of every account.
  """
  @callback accounts(bank :: Bank.Institution.t) :: Bank.Institution.t | {:error, atom, any}

  @doc """
  Like `accounts/1`, but filters the account list by 'type'.
  Some types that could be used:
  - :savings
  - :credit
  - :loans
  """
  @callback accounts(bank :: Bank.Institution.t, type :: atom) :: Bank.Institution.t | {:error, atom, any}

  @doc """
  Populates `Bank.Account.Transaction` objects belonging to an Account, and sets the total balance
  """
  @callback transactions(bank :: Bank.Institution.t, account :: reference, options :: keyword) :: Bank.Institution.t

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    @spec inspect(Bank.Institution.t, Inspect.Opts.t) :: String.t
    def inspect(struct, opts) do
      creds = "#Credentials<" <> Enum.join(Keyword.keys(struct.credentials), ", ") <> ">"
      concat ["#Bank.Institution<", to_doc(Map.delete(%{struct | credentials: creds}, :__struct__), opts), ">"]
    end
  end
end
