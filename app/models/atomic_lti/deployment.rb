module AtomicLti
  class Deployment < ApplicationRecord
    belongs_to :platform, primary_key: :iss, foreign_key: :iss
    belongs_to :install, primary_key: [:iss, :client_id], foreign_key: [:iss, :client_id],  optional: true

    # we won't have platform_guid during dynamic registration
    # belongs_to :platform_instance, primary_key: :guid, foreign_key: :platform_guid, optional: true

    validates :deployment_id, presence: true
    validates :iss, presence: true
    # validates :platform_guid#, presence: true
  end
end
