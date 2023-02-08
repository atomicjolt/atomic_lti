module AtomicLti
  class ErrorHandlingMiddleware
    def initialize(app)
      @app = app
    end

    def render_error(env, status, message)
      format = "text/plain"
      body = message

      render(status, body, format)
    end

    def render(status, body, format)
      [status,
      {
        "Content-Type" => "#{format}; charset=\"UTF-8\"",
        "Content-Length" => body.bytesize.to_s,
      },
      [body]]
    end

    def call(env)
      @app.call(env)

    rescue AtomicLti::Exceptions::AtomicLtiNotFoundException => e
      render_error(env, 404, e.message)

    rescue AtomicLti::Exceptions::AtomicLtiException => e
      render_error(env, 404, e.message)
    end
  end
end
