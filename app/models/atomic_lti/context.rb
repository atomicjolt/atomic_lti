module AtomicLti
  class Context < ApplicationRecord
    belongs_to :platform, primary_key: :iss, foreign_key: :iss
    belongs_to :deployment, primary_key: :deployment_id, foreign_key: :deployment_id

    validates :context_id, presence: true
    validates :deployment_id, presence: true
    validates :iss, presence: true
  end
end
