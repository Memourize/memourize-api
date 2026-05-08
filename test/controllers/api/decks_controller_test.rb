require "test_helper"

class Api::DecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "John Doe",
      email: "test@example.com",
      password: "password"
    )

    @user.decks.create name: "Deck"
  end

  test "should get index" do
    get api_decks_url, headers: authenticated_user(@user)
    assert_response :success

    response_array = JSON.parse response.body
    assert_equal 1, response_array.length
  end

  test "should post create" do
    post api_decks_url, params: { name: "Foo bar!" },
      headers: authenticated_user(@user),
      as: :json
    assert_response :created
  end

  test "should show deck with ready_to_review filter" do
    deck = @user.decks.first
    # Card ready to review (last_view was 5 days ago, last_difficulty was 2)
    # 2 days after last_view is 3 days ago, which is <= today.
    card1 = deck.cards.create!(term: "T1", definition: "D1", last_view: 5.days.ago, last_difficulty: 2)
    # Card NOT ready to review (last_view was yesterday, last_difficulty was 5)
    # 5 days after last_view is in 4 days, which is > today.
    card2 = deck.cards.create!(term: "T2", definition: "D2", last_view: 1.day.ago, last_difficulty: 5)
    # Card with nil last_view or last_difficulty (should now be included when filtered)
    card3 = deck.cards.create!(term: "T3", definition: "D3")

    get api_deck_url(deck, ready_to_review: "true"), headers: authenticated_user(@user)
    assert_response :success

    json_response = JSON.parse(response.body)
    cards = json_response["data"]["cards"]

    assert_equal 2, cards.length, "Expected 2 cards to be ready for review (card1 and card3)"
    card_ids = cards.map { |c| c["id"] }
    assert_includes card_ids, card1.id
    assert_includes card_ids, card3.id
  end
end
