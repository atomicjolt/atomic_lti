module AtomicLti
  class OauthState < ApplicationRecord
    validates :state, presence: true, uniqueness: true
  end
end
