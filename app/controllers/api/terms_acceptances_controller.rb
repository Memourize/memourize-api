class Api::TermsAcceptancesController < ApplicationController
  before_action :authenticate_user!

  # GET /api/terms/acceptance
  # Retorna a versão mais recente aceita pelo usuário (ou null se nunca aceitou).
  def show
    acceptance = current_user.latest_terms_acceptance

    render json: {
      accepted_terms_version: acceptance&.version,
      accepted_at: acceptance&.accepted_at&.utc&.iso8601
    }, status: :ok
  end

  # POST /api/terms/acceptance
  # Body: { "version": "1.0.0" }
  # Registra o aceite. accepted_at é definido pelo servidor; ip_address e
  # user_agent são capturados da própria requisição. Idempotente: aceitar a
  # mesma versão novamente apenas registra um novo evento de histórico, sem erro.
  def create
    version = params[:version]

    if version.blank?
      return render json: { error: "O campo 'version' é obrigatório." }, status: :unprocessable_entity
    end

    acceptance = current_user.terms_acceptances.create!(
      version: version,
      accepted_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: {
      accepted_terms_version: acceptance.version,
      accepted_at: acceptance.accepted_at.utc.iso8601
    }, status: :created
  end
end
