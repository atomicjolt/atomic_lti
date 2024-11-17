module AtomicLti
  class Install < ApplicationRecord
    query_constraints :client_id, :iss
    belongs_to :platform, primary_key: :iss, foreign_key: :iss

    if Rails.version.to_f >= 7.2
      has_many :deployments, foreign_key: [:client_id, :iss]
    else
      has_many :deployments, query_constraints: [:client_id, :iss]
    end

    validates :client_id, presence: true
    validates :iss, presence: true
  end
end
