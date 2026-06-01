require "test_helper"

class Api::AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  test "google_oauth2 callback inclui accepted_terms_version no objeto user" do
    payload = { "email" => "google@example.com", "name" => "Google User" }

    fake_validator = Minitest::Mock.new
    fake_validator.expect(:check, payload) { |_token, _client_id| true }

    GoogleIDToken::Validator.stub(:new, fake_validator) do
      post api_auth_google_oauth2_callback_url, params: { token: "fake-id-token" }
    end

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["user"].key?("accepted_terms_version")
    assert_nil body["user"]["accepted_terms_version"]
  end
end
