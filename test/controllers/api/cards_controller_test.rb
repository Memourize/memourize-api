require "test_helper"

class Api::CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "John Doe",
      email: "test@example.com",
      password: "password"
    )

    @deck = @user.decks.create name: "Deck"
    @card = @deck.cards.create term: "Card", definition: "Definition"
  end

  test "should get index" do
    get "/api/decks/#{@deck.id}/cards", headers: authenticated_user(@user)
    assert_response :success

    response_array = JSON.parse response.body
    assert_equal 1, response_array.length
  end

  test "should post create" do
    body = { term: "Foo", definition: "Bar" }
    post "/api/decks/#{@deck.id}/cards",
      params: body,
      headers: authenticated_user(@user),
      as: :json
    assert_response :success
  end

  test "should patch update" do
    body = { definition: "Definition v2" }
    patch "/api/cards/#{@card.id}",
      params: body,
      headers: authenticated_user(@user),
      as: :json
    assert_response :success
  end

  test "should delete destroy" do
    delete "/api/cards/#{@card.id}", headers: authenticated_user(@user)
    assert_response :success
  end

  test "done advances the definition cursor when the card has alternatives" do
    @card.alternative_definitions.create!(content: "Alt 1", position: 1)
    @card.alternative_definitions.create!(content: "Alt 2", position: 2)

    post "/api/cards/#{@card.id}/done",
      params: { difficulty: 2 },
      headers: authenticated_user(@user),
      as: :json
    assert_response :success
    assert_equal 1, @card.reload.definition_cursor

    post "/api/cards/#{@card.id}/done",
      params: { difficulty: 2 },
      headers: authenticated_user(@user),
      as: :json
    assert_equal 2, @card.reload.definition_cursor

    post "/api/cards/#{@card.id}/done",
      params: { difficulty: 2 },
      headers: authenticated_user(@user),
      as: :json
    assert_equal 0, @card.reload.definition_cursor
  end

  test "done keeps cursor at 0 when the card has no alternatives" do
    post "/api/cards/#{@card.id}/done",
      params: { difficulty: 2 },
      headers: authenticated_user(@user),
      as: :json
    assert_response :success
    assert_equal 0, @card.reload.definition_cursor
  end
end
