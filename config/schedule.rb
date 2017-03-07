# Since Rails is not initialized in whenever job file
# it's necessary to manualy require config yml files
ENV['RAILS_ENV'] ||= @environment
require 'active_support/all'
require './config/preinitializer'

changes_digest_day = AppConfig.emails.notifications.changes_digest.weekday.to_sym

set :output, 'log/whenever.log'

every changes_digest_day, at: '8 am' do
  rake 'mailer:changes_digest'
end

every 1.month, at: '8 am' do
  rake 'mailer:users_with_rotation_need'
  rake 'slack:users_with_rotation_need'
end

every 1.month, at: 'start of the month at 8am' do
  rake 'mailer:users_with_unread_notifications'
end

every 1.day, at: '8 am' do
  rake 'people:gravatars_download'
  rake 'mailer:users_without_primary_role'
end

every :hour do
  rake 'scheduling:remove_expired_booked_memberships'
end
