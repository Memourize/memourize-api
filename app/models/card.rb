class Card < ApplicationRecord
  belongs_to :deck
  has_many :card_reviews

  scope :ready_to_review, -> {
    where(last_difficulty: nil)
      .or(where(last_view: nil))
      .or(where("date(last_view, '+' || last_difficulty || ' days') <= ?", Date.today.to_s))
  }
end
