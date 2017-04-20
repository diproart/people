module Api
  module V3
    class UsersController < Api::V3::BaseController
      expose(:technical_users) { ScheduledUsersRepository.new.all }

      def technical
        render json: technical_users, each_serializer: Api::V3::UserWithMembershipsSerializer, root: false
      end
    end
  end
end
