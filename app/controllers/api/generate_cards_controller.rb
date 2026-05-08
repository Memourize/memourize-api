class Api::GenerateCardsController < ApplicationController
  before_action :authenticate_user!

  def create
    file, deck_name = generate_cards_params
    return render json: { error: "Arquivo (file) é obrigatório" }, status: :bad_request unless file.present?

    if file.size > MAX_FILE_SIZE
      return render json: { error: "Arquivo muito grande. Máximo permitido: #{MAX_FILE_SIZE / 1.megabyte} MB" }, status: :payload_too_large
    end

    service = GenerateCardsService.new(
      user: current_user,
      file: file,
      deck_name: deck_name
    )
    result = service.call

    if result[:success]
      deck = result[:deck]
      cards = result[:cards]

      render json: {
        success: true,
        deck: { id: deck.id, name: deck.name },
        cards: cards.map { |c| { id: c.id, term: c.term, definition: c.definition } }
      }, status: :created
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("[CardsFromPdfController#create] #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    render json: { success: false, error: "Erro interno: #{e.message}" }, status: :internal_server_error
  end

  private

  MAX_FILE_SIZE = 10.megabytes

  def generate_cards_params
    params.expect(:file, :name)
  end
end
