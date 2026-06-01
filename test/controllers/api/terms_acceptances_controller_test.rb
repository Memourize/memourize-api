require "test_helper"

class Api::TermsAcceptancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "Terms User",
      email: "terms@example.com",
      password: "password"
    )
  end

  # ---------- POST /api/terms/acceptance ----------

  test "POST registra o aceite e retorna versão e accepted_at" do
    post api_terms_acceptance_url,
      params: { version: "1.0.0" },
      headers: authenticated_user(@user)

    assert_response :created
    body = JSON.parse(response.body)

    assert_equal "1.0.0", body["accepted_terms_version"]
    assert_not_nil body["accepted_at"]

    acceptance = @user.terms_acceptances.last
    assert_equal "1.0.0", acceptance.version
  end

  test "POST define accepted_at no servidor (ignora o cliente) e em UTC ISO-8601" do
    post api_terms_acceptance_url,
      params: { version: "1.0.0", accepted_at: "1999-01-01T00:00:00Z" },
      headers: authenticated_user(@user)

    assert_response :created
    body = JSON.parse(response.body)

    # Não confia no accepted_at enviado pelo cliente.
    refute_equal "1999-01-01T00:00:00Z", body["accepted_at"]
    # Formato UTC ISO-8601 terminando em Z.
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, body["accepted_at"])
  end

  test "POST captura ip_address e user_agent da requisição" do
    post api_terms_acceptance_url,
      params: { version: "1.0.0" },
      headers: authenticated_user(@user).merge("User-Agent" => "MemourizeApp/1.2.3")

    assert_response :created
    acceptance = @user.terms_acceptances.last
    assert_equal "MemourizeApp/1.2.3", acceptance.user_agent
    assert acceptance.ip_address.present?
  end

  test "POST é idempotente: aceitar a mesma versão duas vezes não dá erro" do
    post api_terms_acceptance_url, params: { version: "1.0.0" }, headers: authenticated_user(@user)
    assert_response :created

    post api_terms_acceptance_url, params: { version: "1.0.0" }, headers: authenticated_user(@user)
    assert_response :created

    body = JSON.parse(response.body)
    assert_equal "1.0.0", body["accepted_terms_version"]
  end

  test "POST retorna 422 quando version está ausente" do
    post api_terms_acceptance_url, params: {}, headers: authenticated_user(@user)
    assert_response :unprocessable_entity
    assert_no_difference -> { @user.terms_acceptances.count } do
      post api_terms_acceptance_url, params: { version: "" }, headers: authenticated_user(@user)
    end
    assert_response :unprocessable_entity
  end

  test "POST retorna 401 sem JWT" do
    post api_terms_acceptance_url, params: { version: "1.0.0" }
    assert_response :unauthorized
  end

  # ---------- GET /api/terms/acceptance ----------

  test "GET retorna null quando o usuário nunca aceitou" do
    get api_terms_acceptance_url, headers: authenticated_user(@user)

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["accepted_terms_version"]
    assert_nil body["accepted_at"]
  end

  test "GET retorna a versão mais recente aceita (por accepted_at)" do
    @user.terms_acceptances.create!(version: "1.0.0", accepted_at: 2.days.ago)
    latest = @user.terms_acceptances.create!(version: "2.0.0", accepted_at: 1.hour.ago)

    get api_terms_acceptance_url, headers: authenticated_user(@user)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "2.0.0", body["accepted_terms_version"]
    assert_equal latest.accepted_at.utc.iso8601, body["accepted_at"]
  end

  test "GET retorna 401 sem JWT" do
    get api_terms_acceptance_url
    assert_response :unauthorized
  end
end
