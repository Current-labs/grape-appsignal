require 'grape'
require 'appsignal'
require 'active_support'

module Appsignal
  module Grape
    class Middleware < ::Grape::Middleware::Base
      def initialize(app, options = {})
        Appsignal.logger.debug 'Initializing Appsignal::Grape::Middleware'
        @app, @options = app, options
      end

      def call(env)
        ActiveSupport::Notifications.instrument(
          'process_action.grape',
          raw_payload(env)
        ) do |payload|
          begin
            @app.call(env).tap do |response|
              payload[:response_status] = response.status
            end
          ensure
            payload[:params] = env["api.endpoint"].params.to_hash
            payload[:params].delete("route_info")
            payload[:params].delete("format")
            payload[:action] = "#{payload[:method]} #{env['api.endpoint'].prepare_path('')}"
          end
        end
      end

      def raw_payload(env)
        request = @options.fetch(:request_class, ::Grape::Request).new(env)
        params = request.public_send(@options.fetch(:params_method, :params))
        {
          :method  => request.request_method,
          :path    => request.path
        }
      end
    end
  end
end
