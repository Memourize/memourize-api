require "test_helper"

class Api::PasswordControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "John Doe",
      email: "change_pwd_test@example.com",
      password: "password"
    )
  end

  test "updates the password with a correct current password" do
    patch api_password_url,
      params: { current_password: "password", password: "NewPass123" },
      headers: authenticated_user(@user),
      as: :json
    assert_response :ok
    assert @user.reload.authenticate("NewPass123"), "new password should authenticate"
  end

  test "rejects an incorrect current password" do
    patch api_password_url,
      params: { current_password: "wrongpass", password: "NewPass123" },
      headers: authenticated_user(@user),
      as: :json
    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Senha atual incorreta"
    assert @user.reload.authenticate("password"), "password should be unchanged"
  end

  test "rejects a too-short new password" do
    patch api_password_url,
      params: { current_password: "password", password: "short" },
      headers: authenticated_user(@user),
      as: :json
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("password"), "password should be unchanged"
  end

  test "requires authentication" do
    patch api_password_url,
      params: { current_password: "password", password: "NewPass123" },
      as: :json
    assert_response :unauthorized
  end
end
