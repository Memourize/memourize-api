require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "password_reset_email" do
    user = users(:one)
    mail = UserMailer.password_reset_email(user, "123456")
    assert_equal "Sua senha do Memorize", mail.subject
    assert_equal [ user.email ], mail.to
    assert_match "123456", mail.body.encoded
  end
end
