defmodule Ueberauth.Strategy.Github.OAuthTest do
  use ExUnit.Case

  import Plug.Conn, only: [put_private: 3]

  alias Ueberauth.Strategy.Github.OAuth, as: GithubOAuth
  alias Plug.Conn

  setup do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth, [], persistent: true)
    Application.put_env(:ueberauth_github, :oauth2_client, TestOAuthClient, persistent: true)
    Application.put_env(:ueberauth_github, :oauth2_module, TestOAuth, persistent: true)
  end

  def auth_conn(test_params, url) do
    %Conn{params: %{"scope" => "user,public_repo,gist"}}
    |> Plug.Adapters.Test.Conn.conn("GET", url, test_params)
    |> put_private(:ueberauth_request_options, [options: [:oauth2_module, Ueberauth.Strategy.Github.OAuth]])
    |> put_private(:github_token, %TestOAuthToken{access_token: "foobar"})
  end

  test "client" do
    client = GithubOAuth.client
    expected =
      %OAuth2.Client{authorize_url: "/oauth/authorize",
                     client_id: "",
                     client_secret: "",
                     headers: [],
                     params: %{},
                     redirect_uri: "",
                     site: "",
                     strategy: OAuth2.Strategy.AuthCode,
                     token: nil,
                     token_method: :post,
                     token_url: "/oauth/token"}

    assert client == expected
  end

  test "get" do
    {:ok, response} = GithubOAuth.get(%TestOAuthToken{}, "http://foo.xyz", [], [])
    expected =
      %OAuth2.Response{body: %{emails: "foo@bar.com"},
                       headers: [],
                       status_code: 200}

    assert response == expected
  end
end
