defmodule Bank.Institution.BACNicaragua do
  @moduledoc """
  BAC Nicaragua SOAP/JSON API fetcher
  """
  use Bank.Institution, name: "BAC Nicaragua"

  use Tesla, only: ~w(get post)a, docs: false

  require EEx

  # Key extracted from the bank's Android APK
  @des3_key ["tmzr1oau", "a9cdfg+2", "5-xpmn=="]
  # yay for insecure crypto!
  @ivec <<0, 0, 0, 0, 0, 0, 0, 0>>

  plug Tesla.Middleware.BaseUrl, "https://www.e-bac.net/sbefx/"
  adapter Tesla.Adapter.Hackney

  # === Behaviour implementation ===

  @lint {Credo.Check.Readability.Specs, false}
  def init([username: username, password: password]) do
    super([username: username, password: encrypt_password(password)])
  end

  @spec accounts(Bank.Institution.t, atom) :: Bank.Institution.t | {:error, atom, any}
  def accounts(%Bank.Institution{} = bank, type) do
    # We need to sign in before we can get accounts, let's do that and then use our real function
    # Using `with` because we'd like to surface any sign-in errors to the caller
    with {:ok, bank} <- sign_in(bank), do: accounts(bank, type)
  end
  def accounts(%Bank.Institution{credentials: [token: _token]} = bank, type) do
    # There's a token in our credentials, so we should be signed in. Let's go ahead and get the accounts
    get_accounts(bank, type)
  end

  # === End Behaviour implementation ===

  defp encrypt_password(password) do
    password
    |> :pkcs7.pad
    |> des3_ecb_encrypt
    |> Base.encode64
  end

  defp des3_ecb_encrypt(password, crypto \\ "")
  defp des3_ecb_encrypt("", crypto), do: crypto
  defp des3_ecb_encrypt(<<to_encrypt :: bytes-size(8)>> <> password, crypto) do
    des3_ecb_encrypt(password, crypto <> :crypto.block_encrypt(:des3_cbc, @des3_key, @ivec, to_encrypt))
  end

  EEx.function_from_file(:defp, :generate_json_signin,
    Path.join(__DIR__, "bac/signin.json.eex"), [:username, :encrypted_password])

  defp sign_in(%Bank.Institution{credentials: [username: username, password: password]} = bank) do
    with payload <- String.trim(generate_json_signin(username, password)),
         %Tesla.Env{status: 200, body: body} <- post("/resources/jsonbac",
                                                     payload, headers: %{"Content-Type": "application/json"}),
         {:ok, body} <- Poison.decode(body),
         IO.inspect(body), # TODO: REMOVE
         bank <- update_token(bank, body)
    do
      {:ok, bank}
    else
      error -> {:error, :signin, error}
    end
  end

  # The token changes after every request, so it must be kept updated.
  # This function expects a pre-decoded JSON body
  defp update_token(%Bank.Institution{} = bank, %{"message" => %{"header" => %{"origin" => %{"token" => token}}}}) do
    %{bank | credentials: Keyword.put(bank.credentials, :token, token)}
  end

  EEx.function_from_file(:defp, :generate_account_list,
    Path.join(__DIR__, "bac/list_accounts.json.eex"), [:username, :token])

  defp get_accounts(%Bank.Institution{credentials: [username: username, token: token]} = bank, :all) do
    with payload <- String.trim(generate_account_list(username, token)),
         %Tesla.Env{status: 200, body: body} <- post("/resources/jsonbac",
                                                              payload, headers: %{"Content-Type": "application/json"}),
         {:ok, body} <- Poison.decode(body),
         IO.inspect(body), # TODO: REMOVE
         bank <- update_token(bank, body),
         bank = %{bank | accounts: build_accounts(body)},
    do: bank
  end
  defp get_accounts(credentials, :savings), do: nil
  defp get_accounts(credentials, :credit), do: nil
  defp get_accounts(credentials, :loans), do: nil

  # This function receives a JSON body and returns a list of Bank.Account structs
  defp build_accounts(%{"message" => %{"body" => %{"userProductsView" => %{"internetAccounts" => accounts}}}}) do
    do_build_accounts(accounts)


  end

  defp do_build_accounts(to_parse, accounts \\ [])
  defp do_build_accounts([], accounts), do: accounts
  defp do_build_accounts([%{"customers" => customers} | rest], accounts) do
    do_build_accounts(rest, do_build_accounts(customers) ++ accounts)
  end
  defp do_build_accounts([%{"productViews" => products} | rest], accounts) do
    do_build_accounts(rest, do_build_accounts(products) ++ accounts)
  end
  defp do_build_accounts([%{"productType" => "TAR"} = product | rest], accounts) do
    # This bank is so shitty that we need to special-case credit card accounts to create two separate accounts:
    # One for the local currency, and one for USD
    with localProduct <- %Bank.Account{
                            bank: __MODULE__,
                            currency: to_iso_currency(product["productCurrency"]),
                            type: :credit,
                            balance: product["available"]
                          },
         usdProduct <- %Bank.Account{
                          bank: __MODULE__,
                          currency: :USD,
                          type: :credit,
                          balance: product["usdavailable"]
                        },
    do: do_build_accounts(rest, [localProduct | [ usdProduct | accounts]])
  end
  defp do_build_accounts([%{"product" => _} = product | rest], accounts) do
    product = %Bank.Account{
        bank: __MODULE__,
        currency: to_iso_currency(product["productCurrency"]),
        type: to_account_type(product["productType"]),
        balance: product["available"]
    }
    do_build_accounts(rest, [product | accounts])
  end

  defp to_iso_currency("COR"), do: :NIO
  defp to_iso_currency(currency), do: String.to_atom(currency)

  defp to_account_type("CBK"), do: :savings
  defp to_account_type("LNS"), do: :loan
  defp to_account_type("TAR"), do: :credit


  # TODO: Transactions at /services/WebServicePublisherMessageSessionService

end
