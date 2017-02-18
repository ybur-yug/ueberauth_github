defmodule TestOAuthToken do
  @type access_token  :: binary
  @type refresh_token :: binary
  @type expires_at    :: integer
  @type token_type    :: binary
  @type other_params  :: %{}
  @type body          :: binary | %{}

  @type t :: %__MODULE__{
              access_token:  access_token,
              refresh_token: refresh_token,
              expires_at:    expires_at,
              token_type:    token_type,
              other_params:  other_params}

  defstruct access_token: "",
            refresh_token: nil,
            expires_at: nil,
            token_type: "Bearer",
            other_params: %{}
end

defmodule TestOAuthClient do
  def new(_opts), do: %OAuth2.Client{}
  def get(_token, _url, _headers, _opts), do: {:ok, %OAuth2.Response{status_code: 200, body: %{emails: "foo@bar.com"}}}
  def authorize_url!(_, _), do: "/oauth/authorize?client_id=&redirect_uri=&response_type=code"
  def get_token!(client, params, headers, opts) do
    %{client | headers: [], params: %{}, token: %TestOAuthToken{}}
  end
end

defmodule TestOAuth do
  def get_token!(data), do: %TestOAuthToken{access_token: data[:code]}
  def authorize_url!(opts), do: opts[:redirect_uri]
end

ExUnit.start()
