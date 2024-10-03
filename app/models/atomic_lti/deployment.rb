module AtomicLti
  class Deployment < ApplicationRecord
    query_constraints :deployment_id, :iss
    belongs_to :platform, primary_key: :iss, foreign_key: :iss
    belongs_to :install, query_constraints: [:client_id, :iss], optional: true
    has_many :contexts, query_constraints: [:deployment_id, :iss]

    # we won't have platform_guid during dynamic registration
    # belongs_to :platform_instance, primary_key: :guid, foreign_key: :platform_guid, optional: true

    validates :deployment_id, presence: true
    validates :iss, presence: true
    # validates :platform_guid#, presence: true
  end
end
