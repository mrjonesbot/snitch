module Snitch
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue Exception => e
      begin
        ExceptionHandler.handle(e, env)
      rescue => handler_error
        Rails.logger.error("[Snitch] Handler error: #{handler_error.message}") if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      end
      raise e
    end
  end
end
