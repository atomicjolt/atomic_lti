require "jwt"

module AtomicLti
  module LtiLaunchSupport
    extend ActiveSupport::Concern

    def lti
      @_lti
    end

    protected

    def do_lti
      params["id_token"].present? or raise Exceptions::NotAnLtiLaunch, "Not an LTI launch"

      @_lti = AtomicLti::LtiRequest.new(request)

      update_lti_models

      user = user_from_lti
      user.confirm unless user.confirmed?
      sign_in(user, event: :authentication)
    end

    def lti_advantage?
      lti&.lti_advantage?
    end

    def lti_launch?
      lti.present?
    end

    def lti_provider
      lti&.lti_provider
    end

    def user_from_lti
      begin
        tries ||= 0
        lti.user_from_lti
      rescue ActiveRecord::RecordNotUnique => e
        # Retry once in case we created the same user twice.  This happens when multiple
        # launches appear on the same page for a new user.
        raise e if (tries += 1) > 1

        # Give the other process a chance to fully create the user. We should find a better solution
        sleep(3)
        retry
      end
    end

    def lti_platform
      AtomicLti::Platform.find_by(iss: lti.iss)
    end

    def lti_install
      @lti_install ||=
        begin
          tries ||= 0
          AtomicLti::Install.find_or_create_by(client_id: lti.client_id, iss: lti.iss)
        rescue ActiveRecord::RecordNotUnique
          retry if (tries += 1) < 2
        end
    end

    def lti_deployment
      @lti_deployment ||=
        begin
          tries ||= 0
          AtomicLti::Deployment.create_with(client_id: lti.client_id,
                                            platform_guid: lti.tool_consumer_instance_guid).
            find_or_create_by!(iss: lti.iss, deployment_id: lti.deployment_id)
        rescue ActiveRecord::RecordNotUnique
          retry if (tries += 1) < 2
        end
    end

    def lti_platform_instance
      @lti_platform_instance ||=
        begin
          tries ||= 0
          AtomicLti::PlatformInstance.find_or_create_by(iss: lti.iss, guid: lti.tool_consumer_instance_guid)
        rescue ActiveRecord::RecordNotUnique
          retry if (tries += 1) < 2
        end
    end

    def lti_context
      @lti_context ||=
        if lti.context_id.present?
          begin
            tries ||= 0
            if AtomicLti.context_scope_to_iss
              AtomicLti::Context.create_with(deployment_id: lti.deployment_id).
                find_or_create_by(context_id: lti.context_id, iss: lti.iss)
            else
              AtomicLti::Context.
                find_or_create_by(context_id: lti.context_id, deployment_id: lti.deployment_id, iss: lti.iss)
            end
          rescue ActiveRecord::RecordNotUnique
            retry if (tries += 1) < 2
          end
        end
    end

    def update_lti_models
      lti_platform
      lti_install
      lti_platform_instance.update(
        name: lti.tool_platform_data["name"],
        version: lti.tool_platform_data["version"],
        product_family_code: lti.tool_platform_data["product_family_code"],
      )
      lti_deployment.update(client_id: lti.client_id, platform_guid: lti.tool_consumer_instance_guid)
      lti_context&.update(
        label: lti.context_data["label"],
        title: lti.context_data["title"],
        types: lti.context_data["type"],
      )
    end

  end
end
