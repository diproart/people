class GoogleUserBuilder
  attr_reader :oauth_data, :user

  def initialize(oauth_data)
    @oauth_data = oauth_data.with_indifferent_access
  end

  def call
    find_user
    if user.present?
      update_user_tokens
      return user
    else
      # send_notifications
      create_user
    end
  end

  private

  def create_user
    user = User.create!(new_user_attributes)
    CreateRatesForUserJob.perform_async(user_id: user.id) if user.present?
    user
  end

  def new_user_attributes
    fields = %w(first_name last_name email)
    attributes = fields.reduce({}) { |mem, key| mem.merge(key => oauth_data['info'][key]) }
    attributes.merge!({
      password: Devise.friendly_token[0, 20],
      uid: oauth_data['uid'],
      oauth_token: oauth_data['credentials']['token'],
      refresh_token: oauth_data['credentials']['refresh_token'],
      oauth_expires_at: oauth_data['credentials']['expires_at']
    })
  end

  def find_user
    @user ||= User.where('uid = ? OR email = ?', oauth_data['uid'], oauth_data['info']['email']).first
  end

  def update_user_tokens
    attributes = {
      oauth_token: oauth_data['credentials']['token'],
      oauth_expires_at: oauth_data['credentials']['expires_at']
    }
    attributes[:refresh_token] = oauth_data['credentials']['refresh_token'] if user.refresh_token.nil?
    attributes[:uid] = oauth_data['uid'] if user.uid.blank?
    user.update_attributes!(attributes)
  end

  def send_notifications
    UserMailer.notify_operations(oauth_data['info']['email']).deliver
    SendMailJob.perform_async(UserMailer, :notify_operations, oauth_data['info']['email'])
  end
end
