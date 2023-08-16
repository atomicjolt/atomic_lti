module AtomicLti
  class OpenIdState < ApplicationRecord
    validates :nonce, presence: true, uniqueness: true
    validates :state, presence: true, uniqueness: true
  end
end
