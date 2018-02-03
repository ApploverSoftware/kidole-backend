# frozen_string_literal: true

module Api
  module V1
    class UsersController < Api::V1::ApiController
      protect_from_forgery with: :null_session
      skip_before_action :authenticate_user, only: %i[show create]

      expose :user, -> { User.find_by(username: params[:username])}
      expose :users, -> { User.all }

      def create
        @user = User.new(user_params)
        if @user.save
          render status: :created
        else
          render status: :unprocessable_entity
        end
      end

      def show
        return record_not_found unless user
        @stats = user.get_balances
      end

      private

      def user_params
        params.require(:user).permit(:password, :password_confirmation, :phone_number, :username, :first_name,
                                     :last_name)
      end
    end
  end
end
