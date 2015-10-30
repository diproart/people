module Scheduling
  class BookedCheck
    def call
      booked_users.each do |user|
        user.memberships.each do |user_membership|
          user_membership.destroy if user_booked_state_has_ended?(user_membership)
        end
      end
    end

    private

    EXPIRATION_TIME = 7.days

    def booked_users
      @booked_users ||= User.includes(:memberships).where(memberships: { booked: true })
    end

    def user_booked_state_has_ended?(membership)
      membership.booked_at.to_date + EXPIRATION_TIME < Date.today
    end
  end
end
