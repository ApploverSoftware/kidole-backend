module Api
  module V1
    class AuthTokensController < Api::V1::ApiController
      skip_before_action :authenticate_user, only: %i[create destroy]

      def create
        binding.pry
        user = User.find_by(username: params[:username])
        return invalid_login_attempt unless user
        if user.authenticate(params[:password])
          auth_token = user.generate_auth_token
          render json: { auth_token: auth_token, user: user }, status: :created
        else
          invalid_login_attempt
        end
      end

      def destroy
        authenticate_with_http_token do |token, _options|
          user = current_user
          user.invalidate_auth_token(token, request.headers[:username], request.headers[:device])
          render json: { success: { details: "User successfully signed out." } }
        end
      end

      private

      def invalid_login_attempt
        render json: { errors: [{ details: "Error with your username or password" }] }, status: :unprocessable_entity
      end

    end
  end
end
