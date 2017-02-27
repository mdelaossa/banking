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

  @spec init(keyword) :: Bank.Institution.t
  def init([username: username, password: password]) do
    super([username: username, password: encrypt_password(password)])
  end

  @spec accounts(Bank.Institution.t) :: [Bank.Account.t]
  def accounts(%Bank.Institution{} = bank) do
    get_accounts(bank.credentials)
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

  EEx.function_from_file(:defp, :generate_json_signin, Path.absname("./lib/bank/institution/bac/json_signin.json.eex"),
                         [:username, :encrypted_password])

  defp sign_in(%Bank.Institution{credentials: [username: username, password: password]} = bank) do
    with payload <- String.trim(generate_json_signin(username, password)),
         %Tesla.Env{status: 200, body: body} <- post("/resources/jsonbac",
                                                     payload, headers: %{"Content-Type": "application/json"}),
         {:ok, body} <- Poison.decode(body),
         token <- body["header"]["origin"]["token"]
    do
      {:ok, %{bank | credentials: Keyword.put(bank.credentials, :token, token)}}
    else
      error = %Tesla.Env{} -> {:error, :http, error}
      _ -> {:error, :error, bank}
    end
  end

  # The token changes after every request, so it must be kept updated
  defp update_token(%Bank.Institution{}, response) do

  end

  defp get_accounts(credentials) do
    # https://www.e-bac.net/sbefx/services/WebServicePublisherMessageSessionService
  end
end
