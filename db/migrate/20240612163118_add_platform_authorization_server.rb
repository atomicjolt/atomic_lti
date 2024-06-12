class AddPlatformAuthorizationServer < ActiveRecord::Migration[7.0]
  def change
    add_column :atomic_lti_platforms, :authorization_server, :string
  end
end
