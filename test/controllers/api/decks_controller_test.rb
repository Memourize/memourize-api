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

  test "show with ready_to_review returns the current view definition" do
    deck = @user.decks.first
    card = deck.cards.create!(term: "T", definition: "Original", last_view: 5.days.ago, last_difficulty: 2)
    card.alternative_definitions.create!(content: "Alt 1", position: 1)
    card.update!(definition_cursor: 1)

    get api_deck_url(deck, ready_to_review: "true"), headers: authenticated_user(@user)
    assert_response :success

    cards = JSON.parse(response.body)["data"]["cards"]
    returned = cards.find { |c| c["id"] == card.id }
    assert_equal "Alt 1", returned["definition"]
  end

  test "show with ready_to_review falls back to original when cursor points nowhere" do
    deck = @user.decks.first
    card = deck.cards.create!(term: "T", definition: "Original", last_view: 5.days.ago, last_difficulty: 2)
    card.update!(definition_cursor: 9)

    get api_deck_url(deck, ready_to_review: "true"), headers: authenticated_user(@user)
    assert_response :success

    cards = JSON.parse(response.body)["data"]["cards"]
    returned = cards.find { |c| c["id"] == card.id }
    assert_equal "Original", returned["definition"]
  end

  test "show with ready_to_review never leaks alternative definitions or cursor" do
    deck = @user.decks.first
    card = deck.cards.create!(term: "T", definition: "Original", last_view: 5.days.ago, last_difficulty: 2)
    card.alternative_definitions.create!(content: "Alt 1", position: 1)

    get api_deck_url(deck, ready_to_review: "true"), headers: authenticated_user(@user)
    cards = JSON.parse(response.body)["data"]["cards"]
    returned = cards.find { |c| c["id"] == card.id }
    assert_not returned.key?("alternative_definitions")
    assert_not returned.key?("definition_cursor")
  end

  test "show without ready_to_review returns the original definition" do
    deck = @user.decks.first
    card = deck.cards.create!(term: "T", definition: "Original")
    card.alternative_definitions.create!(content: "Alt 1", position: 1)
    card.update!(definition_cursor: 1)

    get api_deck_url(deck), headers: authenticated_user(@user)
    assert_response :success

    cards = JSON.parse(response.body)["data"]["cards"]
    returned = cards.find { |c| c["id"] == card.id }
    assert_equal "Original", returned["definition"]
    assert_not returned.key?("definition_cursor")
  end

  test "should export deck as shareable json" do
    deck = @user.decks.first
    card = deck.cards.create!(term: "Hello", definition: "Ola")
    card.alternative_definitions.create!(content: "Cumprimento", position: 1)

    get "/api/decks/#{deck.id}/export", headers: authenticated_user(@user)
    assert_response :success

    json_response = JSON.parse(response.body)["data"]
    assert_equal "memourize.deck", json_response["format"]
    assert_equal 1, json_response["version"]
    assert_equal "Deck", json_response["deck"]["name"]
    assert_equal [
      {
        "term" => "Hello",
        "definition" => "Ola",
        "alternative_definitions" => [
          { "content" => "Cumprimento", "position" => 1 }
        ]
      }
    ], json_response["deck"]["cards"]
  end

  test "should export the requested deck only" do
    first_deck = @user.decks.first
    first_deck.update!(name: "Deck 1")
    first_deck.cards.create!(term: "T1", definition: "D1")

    second_deck = @user.decks.create!(name: "Deck 2")
    second_deck.cards.create!(term: "T2", definition: "D2")

    get "/api/decks/#{second_deck.id}/export", headers: authenticated_user(@user)
    assert_response :success

    json_response = JSON.parse(response.body)["data"]
    assert_equal "Deck 2", json_response["deck"]["name"]
    assert_equal [ "T2" ], json_response["deck"]["cards"].map { |card| card["term"] }
  end

  test "should import shared deck json for authenticated user" do
    other_user = User.create!(
      full_name: "Jane Doe",
      email: "jane@example.com",
      password: "password"
    )

    payload = {
      format: "memourize.deck",
      version: 1,
      deck: {
        name: "Deck compartilhado",
        cards: [
          {
            term: "T1",
            definition: "D1",
            alternative_definitions: [
              { content: "Alt 1", position: 1 },
              { content: "Alt 2", position: 2 }
            ]
          },
          { term: "T2", definition: "D2" }
        ]
      }
    }
    original_user_decks_count = @user.decks.count

    post "/api/decks/import",
      params: payload,
      headers: authenticated_user(other_user),
      as: :json

    assert_response :created

    imported_deck = other_user.decks.find_by!(name: "Deck compartilhado")
    assert_equal 2, imported_deck.cards.count
    assert_equal [ "T1", "T2" ], imported_deck.cards.order(:id).pluck(:term)
    assert_equal [ "Alt 1", "Alt 2" ], imported_deck.cards.order(:id).first.alternative_definitions.order(:position).pluck(:content)
    assert_equal original_user_decks_count, @user.decks.reload.count
  end

  test "should reject data wrapped import json" do
    other_user = User.create!(
      full_name: "Jane Doe",
      email: "jane-export@example.com",
      password: "password"
    )
    exported_deck = @user.decks.first
    exported_deck.cards.create!(term: "T1", definition: "D1")

    get "/api/decks/#{exported_deck.id}/export", headers: authenticated_user(@user)
    exported_payload = JSON.parse(response.body)

    post "/api/decks/import",
      params: exported_payload,
      headers: authenticated_user(other_user),
      as: :json

    assert_response :unprocessable_entity
  end

  test "should reject invalid import json" do
    post "/api/decks/import",
      params: { deck: { name: "", cards: [ { term: "T1" } ] } },
      headers: authenticated_user(@user),
      as: :json

    assert_response :unprocessable_entity
  end
end
