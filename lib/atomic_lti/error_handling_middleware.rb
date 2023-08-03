module AtomicLti
  class ErrorHandlingMiddleware
    def initialize(app)
      @app = app
    end

    def render_error(status, message)
      format = "text/plain"
      body = message

      render(status, body, format)
    end

    def render(status, body, format)
      [
        status,
        {
          "Content-Type" => "#{format}; charset=\"UTF-8\"",
          "Content-Length" => body.bytesize.to_s,
        },
        [body],
      ]
    end

    def call(env)
      @app.call(env)
    rescue JWT::ExpiredSignature
      render_error(401, "The launch has expired. Please launch the application again.")
    rescue JWT::DecodeError
      render_error(401, "The launch token is invalid.")
    rescue AtomicLti::Exceptions::NoLTIToken
      render_error(401, "Invalid launch. Please launch the application again.")
    rescue AtomicLti::Exceptions::AtomicLtiAuthException => e
      render_error(401, "Invalid LTI launch. Please launch the application again. #{e.message}")
    rescue AtomicLti::Exceptions::AtomicLtiNotFoundException => e
      render_error(404, e.message)
    rescue AtomicLti::Exceptions::AtomicLtiException => e
      render_error(500, "Invalid LTI launch. Please launch the application again. #{e.message}")
    end
  end
end
