module AtomicLti
  class Install < ApplicationRecord
    query_constraints :client_id, :iss
    belongs_to :platform, primary_key: :iss, foreign_key: :iss
    has_many :deployments, query_constraints: [:client_id, :iss]

    validates :client_id, presence: true
    validates :iss, presence: true
  end
end
