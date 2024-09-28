module AtomicLti
  class Platform < ApplicationRecord
    validates :iss, presence: true
    has_many :platform_instances, foreign_key: :iss, primary_key: :iss
    has_many :deployments, foreign_key: :iss, primary_key: :iss
    has_many :contexts, foreign_key: :iss, primary_key: :iss
  end
end
