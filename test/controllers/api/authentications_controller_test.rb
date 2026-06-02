require "test_helper"

class Api::AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  test "google_oauth2 callback inclui accepted_terms_version no objeto user" do
    payload = { "email" => "google@example.com", "name" => "Google User" }

    original_validator = GoogleIDToken::Validator
    fake_validator = Class.new do
      define_method(:check) do |_token, _client_id|
        payload
      end
    end

    begin
      GoogleIDToken.send(:remove_const, :Validator)
      GoogleIDToken.const_set(:Validator, fake_validator)

      post api_auth_google_oauth2_callback_url, params: { token: "fake-id-token" }
    ensure
      GoogleIDToken.send(:remove_const, :Validator)
      GoogleIDToken.const_set(:Validator, original_validator)
    end

    assert_response :ok
    body = JSON.parse(response.body)
    assert body["user"].key?("accepted_terms_version")
    assert_nil body["user"]["accepted_terms_version"]
  end
end
