class ApplicationController < ActionController::Base
  include BeforeRender
  include Pundit
  include Flip::ControllerFilters

  expose(:team_members) { fetch_team_members }

  protect_from_forgery with: :exception

  before_filter :authenticate_user!
  before_filter :connect_github
  before_filter :set_gon_data

  before_render :message_to_js

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  decent_configuration do
    strategy DecentExposure::StrongParametersStrategy
  end

  def current_user
    @decorated_cu ||= super.decorate if super.present?
  end

  def current_user?
    user == current_user
  end

  def connect_github
    if signed_in? && !current_user.github_connected?
      redirect_to github_connect_path
    end
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: 'pundit', default: :default
    redirect_to(request.referer || root_path)
  end

  def fetch_team_members
    team = Team.find_by(user_id: current_user.id)

    return [] if team.nil?
    UserDecorator.decorate_collection(
      TeamUsersRepository.new(team).subordinates
    )
  end

  def authenticate_for_skills!
    authorize User, :skill_access?
  end

  def authenticate_admin!
    redirect_to root_path, alert: 'Permission denied! You have no rights to do this.'  unless current_user.admin?
  end

  def set_gon_data
    return unless current_user
    gon.rabl template: 'app/views/layouts/base.rabl', as: 'current_user'
  end

  def message_to_js
    @flashMessage = { notice: [], alert: [] }.with_indifferent_access
    flash.each do |name, msg|
      @flashMessage[name] << msg
    end
    gon.rabl template: 'app/views/layouts/flash.rabl', as: 'flash'
    # flash.clear
  end
end
