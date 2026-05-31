class Api::DecksController < ApplicationController
 before_action :authenticate_user!
 before_action :set_deck, only: [ :show, :update, :destroy ]

  def index
    @decks = current_user.decks
    render json: { data: @decks.as_json(include: :cards) }
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

  private

  def set_deck
    @deck = current_user.decks.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:name)
  end
end
