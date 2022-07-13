module AtomicLti
  module Exceptions
    class LineItemError < StandardError
    end

    class ConfigurationError < StandardError
    end

    class NamesAndRolesError < StandardError
    end

    class ScoreError < StandardError
    end

    class NoLTIDeployment < StandardError
    end

    class NoLTIPlatform < StandardError
    end

    class StateError < StandardError
    end

    class OpenIDStateError < StandardError
    end

    class OpenIDRedirectError < StandardError
    end

  end
end
