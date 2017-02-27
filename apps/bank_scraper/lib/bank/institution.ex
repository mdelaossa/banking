defmodule Bank.Institution do
  @moduledoc """
  Defines the Bank Institution behaviour
  """

  @type t :: %__MODULE__{
                bank: atom,
                name: binary,
                accounts: [Bank.Account.t],
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

      defoverridable [init: 1]
    end
  end

  @doc """
  Returns a Bank.Institution struct with information required to perform further actions.
  The implementing module must ensure to add itself as the `bank` keyword
  """
  @callback init(keyword) :: t

  @doc """
  Returns a list of Account objects belonging to a bank.
  The implementing module must ensure to add itself as the `bank` keyword
  """
  @callback accounts(t) :: [Bank.Account.t]

  @doc """
  Populates Account.Transaction objects belonging to an Account, and sets the total balance
  """
  @callback transactions(Bank.Account.t, keyword()) :: Bank.Account.t

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    @spec inspect(Bank.Institution.t, Inspect.Opts.t) :: String.t
    def inspect(struct, opts) do
      creds = "#Credentials<" <> Enum.join(Keyword.keys(struct.credentials), ", ") <> ">"
      concat ["#Bank.Institution<", to_doc(Map.delete(%{struct | credentials: creds}, :__struct__), opts), ">"]
    end
  end
end
