class ApplicationController < ActionController::API
  private

  JWT_EXPIRATION_TIMESTAMP = 24.hours.from_now.to_i

  def authenticate_user!
    render json: { error: "Não autorizado. Você precisa fazer login." }, status: :unauthorized unless current_user
  end

  def current_user
    @current_user ||= begin
      token = request.headers["Authorization"]&.split(" ")&.last
      return nil unless token

      begin
        decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
        user_id = decoded_token[0]["user_id"]
        User.find_by(id: user_id)
      rescue JWT::DecodeError
        nil
      end
    end
  end

  def issue_jwt_token(user)
    payload = { user_id: user.id, exp: JWT_EXPIRATION_TIMESTAMP }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end
