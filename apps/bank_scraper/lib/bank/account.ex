defmodule Bank.Account do
  @moduledoc """
  Deals with bank accounts: retrieving balance, transactions, etc
  """

  @type t :: %__MODULE__{
             bank: atom,
             currency: atom,
             type: atom,
             balance: integer,
             transactions: [Bank.Account.Transaction.t]
             }
  @enforce_keys [:bank, :type]
  defstruct bank: nil, currency: :USD, type: nil, balance: 0, transactions: []
end
