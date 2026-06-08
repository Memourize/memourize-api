class Api::DecksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck, only: [ :show, :update, :destroy, :export ]

  def index
    @decks = current_user.decks
    render json: {
      data: @decks.map do |deck|
        deck.as_json(include: :cards)
            .merge("cards_to_review" => deck.cards.ready_to_review.count)
      end
    }
  end

  def show
    if params[:ready_to_review] == "true"
      cards = @deck.cards.ready_to_review.map do |card|
        card.as_json(except: :definition_cursor).merge("definition" => card.current_definition)
      end
    else
      cards = @deck.cards.as_json(except: :definition_cursor)
    end

    render json: { data: @deck.as_json.merge(cards: cards) }
  end

  def create
    @deck = current_user.decks.build(deck_params)

    if @deck.save
      render json: { data: @deck }, status: :created
    else
      render json: { errors: @deck.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @deck.update deck_params
    head :ok
  end

  def destroy
    @deck.destroy
    head :no_content
  end

  def export
    render json: { data: deck_export_json(@deck) }
  end

  def import
    deck_data = import_deck_params
    cards_data = deck_data[:cards]

    ActiveRecord::Base.transaction do
      @deck = current_user.decks.create!(name: deck_data[:name])

      cards_data.each do |card_data|
        card = @deck.cards.create!(
          term: card_data[:term],
          definition: card_data[:definition]
        )

        card_data[:alternative_definitions]&.each do |alternative_definition_data|
          card.alternative_definitions.create!(
            content: alternative_definition_data[:content],
            position: alternative_definition_data[:position]
          )
        end
      end
    end

    render json: {
      data: @deck.as_json.merge(cards: @deck.cards.order(:id).as_json(except: :definition_cursor))
    }, status: :created
  rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  private

  def set_deck
    @deck = current_user.decks.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:name)
  end

  def import_deck_params
    deck_data = params.require(:deck).permit(
      :name,
      cards: [
        :term,
        :definition,
        { alternative_definitions: [ :content, :position ] }
      ]
    )
    cards_data = deck_data[:cards]

    raise ArgumentError, "Nome do deck é obrigatório" if deck_data[:name].blank?
    raise ArgumentError, "Cards devem ser enviados em uma lista" unless cards_data.is_a?(Array)

    cards_data.each_with_index do |card_data, index|
      if card_data[:term].blank? || card_data[:definition].blank?
        raise ArgumentError, "Card #{index + 1} deve ter term e definition"
      end

      card_data[:alternative_definitions]&.each_with_index do |alternative_definition_data, alternative_definition_index|
        if alternative_definition_data[:content].blank? || alternative_definition_data[:position].blank?
          raise ArgumentError, "Definição alternativa #{alternative_definition_index + 1} do card #{index + 1} deve ter content e position"
        end
      end
    end

    deck_data
  end

  def deck_export_json(deck)
    {
      format: "memourize.deck",
      version: 1,
      deck: {
        name: deck.name,
        cards: deck.cards.order(:id).map do |card|
          {
            term: card.term,
            definition: card.definition,
            alternative_definitions: card.alternative_definitions.order(:position).map do |alternative_definition|
              {
                content: alternative_definition.content,
                position: alternative_definition.position
              }
            end
          }
        end
      }
    }
  end
end
