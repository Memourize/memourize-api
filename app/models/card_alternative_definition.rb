class CardAlternativeDefinition < ApplicationRecord
  belongs_to :card

  validates :content, presence: true
  validates :position, presence: true
end
