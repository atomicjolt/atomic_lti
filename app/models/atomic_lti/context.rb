module AtomicLti
  class Context < ApplicationRecord
    query_constraints :context_id, :deployment_id, :iss
    belongs_to :platform, primary_key: :iss, foreign_key: :iss

    if Rails.version.to_f >= 7.2
      belongs_to :deployment, foreign_key: [:iss, :deployment_id], optional: true
    else
      belongs_to :deployment, query_constraints: [:iss, :deployment_id], optional: true
    end

    validates :context_id, presence: true
    validates :deployment_id, presence: true
    validates :iss, presence: true
  end
end
