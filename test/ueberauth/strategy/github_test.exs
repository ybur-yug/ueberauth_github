defmodule Ueberauth.Strategy.GithubTest do
  use ExUnit.Case

  import Plug.Conn, only: [put_private: 3]

  alias Ueberauth.Strategy.Github
  alias Plug.Conn

  setup do
    Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth, [], persistent: true)
    Application.put_env(:ueberauth_github, :oauth2_client, TestOAuthClient, persistent: true)
    Application.put_env(:ueberauth_github, :oauth2_module, TestOAuth, persistent: true)
    Application.put_env(:ueberauth_github, :uid_field, :login, persistent: true)
  end

  def auth_conn(test_params, url) do
    %Conn{params: %{"scope" => "user,public_repo,gist"}}
    |> Plug.Adapters.Test.Conn.conn("GET", url, test_params)
    |> put_private(:ueberauth_request_options, [options: [:oauth2_module, Ueberauth.Strategy.Github.OAuth]])
    |> put_private(:github_token, %TestOAuthToken{access_token: "foobar"})
  end

  test "handle_request" do
    conn =
      %{}
      |> auth_conn("https://github.com/authorized/")
      |> Github.handle_request!
    expected_html          = "<html><body>You are being <a href=\"https://github.com\">redirected</a>.</body></html>"

    assert conn.halted
    assert conn.request_path == "/authorized/"
    assert conn.resp_body == expected_html
    assert conn.status == 302
  end

  test "handle callback" do
    conn =
      %{code: "foobar"}
      |> auth_conn("http://github.com/authorized")
      |> Github.handle_callback!

    assert conn.private.github_token
    assert conn.private.github_user
  end

  test "handle cleanup" do
    conn =
      %{}
      |> auth_conn("http://github.com/authorized/")
      |> put_private(:github_user, "bobdawg")
      |> put_private(:token, "abc123")
      |> Github.handle_cleanup!

    refute conn.private[:github_user]
    refute conn.private[:github_token]
  end

  test "retrieve uid" do
    result =
      %{}
      |> auth_conn("http://github.com/authorized")
      |> put_private(:github_user, %{"Elixir.TestOAuth" => %{email: "foo@bar.com"}})
      |> Github.uid

    assert result == %{email: "foo@bar.com"}
  end

  test "retrieve credentials" do
    credentials =
      %{code: "foobar"}
      |> auth_conn("http://github.com/authorized")
      |> Github.credentials
    expected =
      %Ueberauth.Auth.Credentials{expires: false,
                                  expires_at: nil,
                                  other: %{},
                                  refresh_token: nil,
                                  scopes: [""],
                                  secret: nil,
                                  token: "foobar",
                                  token_type: "Bearer"}

    assert credentials == expected
  end

  test "retrieve info" do
    %{code: "foobar"}
    |> auth_conn("http://github.com/authorized")
    |> put_private(:github_user, %{})
    |> put_private(:github_token, %TestOAuthToken{access_token: "fizz"})
    |> Github.info
    |> assert
  end

  test "retrieve extra" do
    %{code: "foobar"}
    |> auth_conn("http://github.com/authorized")
    |> put_private(:github_user, %{})
    |> put_private(:github_token, %TestOAuthToken{access_token: "fizz"})
    |> Github.extra
    |> assert
  end
end
