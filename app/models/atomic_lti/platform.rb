module AtomicLti
  class Platform < ApplicationRecord
    validates :iss, presence: true
  end
end
