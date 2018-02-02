# frozen_string_literal: true

module Api
  module V1
    class ApiController < ActionController::Base
      protect_from_forgery with: :null_session
      include ActionController::HttpAuthentication::Token::ControllerMethods

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      def record_not_found
        render json: { errors: { exceptions: 'record_not_found' } }, status: :not_found
      end

      def current_user
        @current_user ||= authenticate_token(request.headers[:username], request.headers[:device])
      end

      private

      def authenticate_user
        authenticate_token(request.headers[:username], request.headers[:device])
      end

      def authenticate_token(username, device)
        authenticate_with_http_token do |token, _options|
          if (token = User.authenticated(token, username, device))
            return token.user
          end
        end
        render json: { errors: [{ detail: 'Access denied, wrong username or token' }] }, status: :unprocessable_entity
      end
    end
  end
end
