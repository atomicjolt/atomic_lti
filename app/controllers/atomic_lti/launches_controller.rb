module AtomicLti
  class LaunchesController < ::ApplicationController
    include AtomicLti::LtiLaunchSupport

    skip_before_action :verify_authenticity_token
    before_action :do_lti

    helper_method :lti_provider, :lti_advantage?, :lti, :lti_launch?

    def index
      render :index
    end

    def show
      render :index
    end

  end
end
