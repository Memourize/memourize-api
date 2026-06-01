class User < ApplicationRecord
  has_secure_password
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :email, presence: true, uniqueness: true

  has_many :decks, dependent: :destroy
  has_many :password_resets, dependent: :destroy
  has_many :terms_acceptances, dependent: :destroy

  # Última (mais recente) aceitação de termo do usuário, por accepted_at.
  def latest_terms_acceptance
    terms_acceptances.order(accepted_at: :desc).first
  end

  # Versão do termo mais recentemente aceita (ou nil se nunca aceitou).
  def accepted_terms_version
    latest_terms_acceptance&.version
  end
end
