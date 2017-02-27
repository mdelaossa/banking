defmodule Bank.Account.Transaction do
  @moduledoc """
  A bank transaction. Value is modeled in cents
  """

  @type t :: %__MODULE__{
             value: integer,
             payee: binary,
             debit: boolean,
             notes: binary | nil,
             category: binary | nil,
             datetime: DateTime.t
             }
  @enforce_keys [:value, :payee, :datetime]
  defstruct value: 0, payee: nil, debit: true, notes: nil, category: nil, datetime: nil
end
