module AtomicLti
  class PlatformInstance < ApplicationRecord
    belongs_to :platform, primary_key: :iss, foreign_key: :iss

    validates :guid, presence: true
    validates :iss, presence: true
  end
end
