class Card < ApplicationRecord
  belongs_to :deck
  has_many :card_reviews
  has_many :alternative_definitions,
           class_name: "CardAlternativeDefinition",
           dependent: :destroy

  scope :ready_to_review, -> {
    where(last_difficulty: nil)
      .or(where(last_view: nil))
      .or(where("date(last_view, '+' || last_difficulty || ' days') <= ?", Date.today.to_s))
  }

  # Total number of "views": the original definition plus each alternative.
  def definition_views_count
    1 + alternative_definitions.size
  end

  # The definition to show for the current cursor position.
  # Cursor 0 is the original; cursor k (1..N) is the alternative at position k.
  # Any cursor that points nowhere falls back to the original.
  def current_definition
    return definition if definition_cursor.zero?

    alt = alternative_definitions.find { |a| a.position == definition_cursor }
    alt ? alt.content : definition
  end

  # Move to the next view, wrapping around. With no alternatives this stays at 0.
  def advance_definition_cursor!
    next_cursor = (definition_cursor + 1) % definition_views_count
    update!(definition_cursor: next_cursor)
  end
end
