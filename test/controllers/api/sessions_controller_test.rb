require "test_helper"

class Api::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "Login User",
      email: "login@example.com",
      password: "password"
    )
  end

  test "login inclui accepted_terms_version no objeto user (null quando nunca aceitou)" do
    post api_login_url, params: { email: @user.email, password: "password" }

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["user"].key?("accepted_terms_version")
    assert_nil body["user"]["accepted_terms_version"]
  end

  test "login reflete a versão mais recente aceita no objeto user" do
    @user.terms_acceptances.create!(version: "1.0.0", accepted_at: Time.current)

    post api_login_url, params: { email: @user.email, password: "password" }

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal "1.0.0", body["user"]["accepted_terms_version"]
  end
end
