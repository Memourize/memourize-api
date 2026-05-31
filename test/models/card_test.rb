require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    user = User.create!(full_name: "A", email: "card@example.com", password: "password")
    deck = user.decks.create!(name: "Deck")
    @card = deck.cards.create!(term: "T", definition: "Original")
  end

  test "current_definition returns original when cursor is 0" do
    assert_equal 0, @card.definition_cursor
    assert_equal "Original", @card.current_definition
  end

  test "current_definition returns the alternative at the cursor position" do
    @card.alternative_definitions.create!(content: "Alt 1", position: 1)
    @card.alternative_definitions.create!(content: "Alt 2", position: 2)
    @card.update!(definition_cursor: 2)
    assert_equal "Alt 2", @card.current_definition
  end

  test "current_definition falls back to original when cursor points nowhere" do
    @card.update!(definition_cursor: 5)
    assert_equal "Original", @card.current_definition
  end

  test "advance_definition_cursor! cycles through views" do
    @card.alternative_definitions.create!(content: "Alt 1", position: 1)
    @card.alternative_definitions.create!(content: "Alt 2", position: 2)

    @card.advance_definition_cursor!
    assert_equal 1, @card.reload.definition_cursor
    @card.advance_definition_cursor!
    assert_equal 2, @card.reload.definition_cursor
    @card.advance_definition_cursor!
    assert_equal 0, @card.reload.definition_cursor
  end

  test "advance_definition_cursor! stays at 0 when there are no alternatives" do
    @card.advance_definition_cursor!
    assert_equal 0, @card.reload.definition_cursor
  end

  test "destroying a card destroys its alternative definitions" do
    @card.alternative_definitions.create!(content: "Alt 1", position: 1)
    assert_difference "CardAlternativeDefinition.count", -1 do
      @card.destroy
    end
  end
end
