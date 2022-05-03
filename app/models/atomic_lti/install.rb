module AtomicLti
  class Install < ApplicationRecord
    belongs_to :platform, primary_key: :iss, foreign_key: :iss

    validates :client_id, presence: true
    validates :iss, presence: true
    def deployments
      AtomicLti::Deployment.where("iss = ? AND client_id = ?", iss, client_id)
    end
  end
end
