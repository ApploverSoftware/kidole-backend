module Api
  module V1
    class UsersController < Api::V1::ApiController
      skip_before_action :authenticate_user, only: [:create]

      expose :user
      expose :users, -> { User.all }

      def create
        if user.save
          render status: :created
        else
          render status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:password, :password_confirmation, :phone_number, :username, :first_name,
                                     :last_name)
      end
    end
  end
end
