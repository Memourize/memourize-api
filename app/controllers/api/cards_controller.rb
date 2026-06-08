class Api::CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_deck, only: [ :index, :create ]
  before_action :set_user_card, only: [ :update, :destroy, :done ]

  def index
    @cards = @deck.cards.all
    render json: { data: @cards }
  end

  def create
    @card = @deck.cards.build(card_params)

    if @card.save
      render json: { data: @card }, status: :created
    else
      render json: { errors: @card.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @card.update(card_params)
      render json: { data: @card }, status: :ok
    else
      render json: { errors: @card.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @card.destroy
    head :no_content
  end

  def done
    ActiveRecord::Base.transaction do
      @card.card_reviews.create!(difficulty: params[:difficulty], date: Date.today)
      @card.update!(last_difficulty: params[:difficulty], last_view: Time.current)
      @card.advance_definition_cursor!
    end
    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_user_deck
    @deck = current_user.decks.find(params[:deck_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Deck não encontrado" }, status: :not_found
  end

  def set_user_card
    @card = Card.joins(:deck).where(decks: { user_id: current_user.id }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Card não encontrado" }, status: :not_found
  end

  def card_params
    params.require(:card).permit(:term, :definition)
  end
end
