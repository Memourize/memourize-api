class Api::PasswordController < ApplicationController
  before_action :authenticate_user!, only: [ :update ]

  def forgot
    email = forgot_params
    @user = User.find_by(email: email)

    unless @user
      head :ok
      return
    end

    PasswordReset.where(user: @user).destroy_all
    code = SecureRandom.random_number(10000).to_s.rjust(4, "0")

    @reset_record = PasswordReset.new(
      user: @user,
      token_hash: BCrypt::Password.create(code),
      expires_at: 10.minutes.from_now
    )

    if @reset_record.save
      UserMailer.password_reset_email(@user, code).deliver_now
      head :ok
    else
      render json: { errors: @reset_record.errors.full_messages }, status: :internal_server_error
    end
  end

  def validate_token
    email, code = validate_params

    if validate(email, code)
      head :ok
    else
      render json: { message: "invalid token" }, status: :bad_request
    end
  end

  def reset_password
    email, code, password = reset_params

    if validate(email, code)
      if @user.update(password: password)
        @reset_record.destroy
        head :ok
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { message: "invalid token" }, status: :bad_request
    end
  end

  def update
    current_password, password = update_params

    unless current_user.authenticate(current_password)
      return render json: { errors: [ "Senha atual incorreta" ] }, status: :unprocessable_entity
    end

    if current_user.update(password: password)
      head :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def validate(email, code)
    @user = User.find_by(email: email)

    unless @user
      return false
    end

    @reset_record = PasswordReset.find_by(user: @user)

    unless @reset_record
      return false
    end

    if @reset_record.max_attempts_reached?
      @reset_record.destroy
      return false
    end

    if @reset_record.expired?
      @reset_record.destroy
      return false
    end

    BCrypt::Password.new(@reset_record.token_hash) == code
  end

  def forgot_params
    params.require(:email)
  end

  def validate_params
    params.require([ :email, :code ])
  end

  def reset_params
    params.require([ :email, :code, :password ])
  end

  def update_params
    params.require([ :current_password, :password ])
  end
end
