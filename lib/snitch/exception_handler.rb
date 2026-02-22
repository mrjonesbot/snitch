module Snitch
  class ExceptionHandler
    class << self
      def handle(exception, env = {})
        return unless Snitch.configuration.enabled
        return if ignored?(exception)

        fingerprint = Fingerprint.generate(exception)
        request_data = extract_request_data(env)

        record = find_or_create_record(exception, fingerprint, request_data)
        enqueue_report(record)
        record
      end

      private

      def ignored?(exception)
        config_ignored = Snitch.configuration.ignored_exceptions.any? do |ignored|
          ignored_class = ignored.is_a?(String) ? ignored.safe_constantize : ignored
          ignored_class && exception.is_a?(ignored_class)
        end
        return true if config_ignored

        Snitch::Event.ignored.where(exception_class: exception.class.name).exists?
      end

      def extract_request_data(env)
        return {} if env.empty?
        request = ActionDispatch::Request.new(env) rescue nil
        return {} unless request

        {
          request_url: request.url,
          request_method: request.method,
          request_params: filtered_params(request)
        }
      end

      def filtered_params(request)
        request.filtered_parameters.to_json rescue request.params.to_json rescue "{}"
      end

      def find_or_create_record(exception, fingerprint, request_data)
        existing = Event.find_by(fingerprint: fingerprint)

        if existing
          attrs = {
            occurrence_count: existing.occurrence_count + 1,
            last_occurred_at: Time.current,
            message: exception.message,
            backtrace: exception.backtrace
          }
          attrs[:status] = "open" if existing.status == "closed"
          existing.update!(**attrs)
          existing
        else
          Event.create!(
            exception_class: exception.class.name,
            message: exception.message,
            backtrace: exception.backtrace,
            fingerprint: fingerprint,
            occurrence_count: 1,
            first_occurred_at: Time.current,
            last_occurred_at: Time.current,
            **request_data
          )
        end
      end

      def enqueue_report(record)
        ReportExceptionJob.perform_later(record.id)
      rescue => e
        Rails.logger.error("[Snitch] Failed to enqueue report job: #{e.message}") if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
      end
    end
  end
end
