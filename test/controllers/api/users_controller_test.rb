require "test_helper"

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  test "cadastro inclui accepted_terms_version no objeto user (null em conta nova)" do
    post api_users_url, params: {
      user: {
        full_name: "New User",
        email: "newuser@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    assert_response :created
    body = JSON.parse(response.body)
    assert body["user"].key?("accepted_terms_version")
    assert_nil body["user"]["accepted_terms_version"]
  end
end
