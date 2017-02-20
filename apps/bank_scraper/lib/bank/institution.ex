defmodule Bank.Institution do
  @moduledoc """
  Defines the Bank Institution behaviour
  """

  @type t :: %Bank.Institution{bank: atom, name: binary, accounts: [%Bank.Account{}], credentials: keyword}
  @enforce_keys [:bank, :name]
  defstruct bank: nil, name: nil, accounts: [], credentials: []

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Bank.Institution

      unless opts[:name] != nil, do: raise ArgumentError, message: ":name option is required when `use`ing Bank.Institution"

      @name opts[:name]

      @spec init(keyword) :: %Bank.Institution{}
      def init(credentials), do: %Bank.Institution{bank: __MODULE__, name: @name, credentials: credentials}

      defoverridable [init: 1]
    end
  end

  @doc """
  Returns a Bank.Institution struct with information required to perform further actions.
  The implementing module must ensure to add itself as the `bank` keyword
  """
  @callback init(keyword) :: %Bank.Institution{}

  @doc """
  Returns a list of Account objects belonging to a bank.
  The implementing module must ensure to add itself as the `bank` keyword
  """
  @callback accounts() :: [%Bank.Account{}]

  @doc """
  Populates Account.Transaction objects belonging to an Account, and sets the total balance
  """
  @callback transactions(%Bank.Account{}, keyword()) :: %Bank.Account{}
end

defimpl Inspect, for: Bank.Institution do
  import Inspect.Algebra

  @spec inspect(%Bank.Institution{}, %Inspect.Opts{}) :: String.t
  def inspect(struct, opts) do
    creds = "#Credentials<" <> Enum.join(Keyword.keys(struct.credentials), ", ") <> ">"
    concat ["#Bank.Institution<", to_doc(Map.delete(%{struct | credentials: creds}, :__struct__), opts), ">"]
  end
end
