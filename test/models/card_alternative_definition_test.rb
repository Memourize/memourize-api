require "test_helper"

class CardAlternativeDefinitionTest < ActiveSupport::TestCase
  setup do
    user = User.create!(full_name: "A", email: "alt@example.com", password: "password")
    deck = user.decks.create!(name: "Deck")
    @card = deck.cards.create!(term: "T", definition: "D")
  end

  test "is valid with content and position" do
    alt = @card.alternative_definitions.build(content: "Other view", position: 1)
    assert alt.valid?
  end

  test "is invalid without content" do
    alt = @card.alternative_definitions.build(position: 1)
    assert_not alt.valid?
    assert_includes alt.errors[:content], "can't be blank"
  end

  test "is invalid without position" do
    alt = @card.alternative_definitions.build(content: "Other view")
    assert_not alt.valid?
    assert_includes alt.errors[:position], "can't be blank"
  end

  test "belongs to card" do
    alt = @card.alternative_definitions.create!(content: "Other view", position: 1)
    assert_equal @card, alt.card
  end
end
