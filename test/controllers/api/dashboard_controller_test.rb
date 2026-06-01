require "test_helper"

class Api::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      full_name: "John Doe",
      email: "test@example.com",
      password: "password"
    )
    @deck = @user.decks.create!(name: "Deck A")
    @other_deck = @user.decks.create!(name: "Deck B")

    # Deck A: 2 fáceis, 1 médio, 1 difícil, 1 não estudado
    @deck.cards.create!(term: "a1", definition: "d", last_difficulty: 7)
    @deck.cards.create!(term: "a2", definition: "d", last_difficulty: 7)
    @deck.cards.create!(term: "a3", definition: "d", last_difficulty: 3)
    @deck.cards.create!(term: "a4", definition: "d", last_difficulty: 1)
    @deck.cards.create!(term: "a5", definition: "d") # last_difficulty nil

    # Deck B: 1 difícil
    @other_deck.cards.create!(term: "b1", definition: "d", last_difficulty: 1)
  end

  def counts_by_difficulty(body)
    body["cards_by_difficulty"].to_h { |b| [ b["difficulty"], b["count"] ] }
  end

  test "returns the four difficulty buckets and totals for all decks" do
    get api_dashboard_url, headers: authenticated_user(@user)
    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 4, body["cards_by_difficulty"].length
    counts = counts_by_difficulty(body)
    assert_equal 2, counts[7]
    assert_equal 1, counts[3]
    assert_equal 2, counts[1]   # a4 + b1
    assert_equal 1, counts[nil] # a5
    assert_equal 6, body["totals"]["total_cards"]
    assert_equal 5, body["totals"]["reviewed_cards"]
  end

  test "filters card counts by deck_id" do
    get api_dashboard_url(deck_id: @deck.id), headers: authenticated_user(@user)
    assert_response :success
    body = JSON.parse(response.body)

    counts = counts_by_difficulty(body)
    assert_equal 2, counts[7]
    assert_equal 1, counts[3]
    assert_equal 1, counts[1]   # only a4
    assert_equal 1, counts[nil]
    assert_equal 5, body["totals"]["total_cards"]
    assert_equal 4, body["totals"]["reviewed_cards"]
  end

  test "returns 404 for a deck that belongs to another user" do
    other_user = User.create!(full_name: "Jane", email: "jane@example.com", password: "password")
    foreign = other_user.decks.create!(name: "Foreign")

    get api_dashboard_url(deck_id: foreign.id), headers: authenticated_user(@user)
    assert_response :not_found
  end
end
