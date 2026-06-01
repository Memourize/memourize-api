class TermsAcceptance < ApplicationRecord
  belongs_to :user

  validates :version, presence: true
  validates :accepted_at, presence: true
end
