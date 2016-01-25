class ScheduledUsersRepository
  def all
    @all_scheduled ||= technical_users.distinct.order(:last_name)
  end

  def not_scheduled
    @not_scheduled ||=
      technical_users
      .where
      .not(id: technical_users_with_valid_memberships.pluck(:id))
      .order(:last_name)
  end

  def scheduled_juniors_and_interns
    @scheduled_juniors_and_interns ||=
      technical_users_with_valid_memberships
      .joins(:positions).available
      .where(positions: { role: non_billable_technical_roles, primary: true })
  end

  def to_rotate
    @to_rotate ||=
      not_booked_billable_users
      .without_scheduled_commercial_memberships.joins(memberships: :project)
      .where(
        projects: { end_at: nil, internal: false },
        memberships: { ends_at: nil })
      .merge(Project.active.nonpotential.not_maintenance)
      .order('COALESCE(memberships.starts_at, projects.starts_at)')
  end

  def in_internals
    @in_internals ||=
      not_booked_billable_users
      .without_scheduled_commercial_memberships.joins(memberships: :project)
      .where(projects: { internal: true })
      .merge(Membership.active.unfinished.started)
  end

  def with_rotations_in_progress
    @with_rotations_in_progress ||=
      not_booked_billable_users
      .joins(memberships: :project)
      .merge(Project.active.unfinished.started.commercial.not_maintenance)
      .merge(Membership.not_started.active.not_internal)
  end

  def in_commercial_projects_with_due_date
    @in_commercial_projects_with_due_date ||=
      not_booked_billable_users
      .without_scheduled_commercial_memberships
      .joins(current_memberships: [:project])
      .where("(projects.internal = 'f') AND (memberships.ends_at > :now OR projects.end_at > :now)", now: 1.day.ago)
      .merge(Project.active.commercial.started.not_maintenance)
      .order('COALESCE(memberships.starts_at, projects.starts_at)')
  end

  def booked
    @booked ||= billable_users.booked
  end

  def unavailable
    @unavailable ||= UnavailableProjectBuilder.new.call
    technical_users.not_booked.unavailable
  end

  def technical
    @technical ||= User.active.includes(
      :primary_roles,
      current_memberships: [:project],
      next_memberships: [:project],
      booked_memberships: [:project]
    ).technical
  end

  private

  def base_users
    @base_users ||= User.active.includes(
      :roles,
      :abilities,
      :projects,
      :longest_current_membership,
      current_memberships: [:project],
      potential_memberships: [:project],
      next_memberships: [:project],
      booked_memberships: [:project],
      positions: [:role],
      primary_role: [:users]
    )
  end

  def technical_users
    @technical_users ||= base_users.technical
  end

  def technical_users_with_valid_memberships
    @technical_users_with_valid_memberships ||=
      technical_users
      .joins(memberships: :project)
      .where('(memberships.ends_at IS NULL OR memberships.ends_at > :now) AND (projects.end_at IS NULL OR projects.end_at > :now)', now: Time.now)
      .distinct
  end

  def billable_users
    @billable_users ||=
      base_users
      .joins(:positions)
      .where(positions: { role: billable_technical_roles, primary: true })
  end

  def not_booked_billable_users
    @not_booked_billable_users ||= billable_users.not_booked.available
  end

  def non_billable_technical_roles
    @non_billable_technical_roles ||= Role.technical.non_billable
  end

  def billable_technical_roles
    @billable_technical_roles ||= Role.technical.billable
  end

  def technical_roles_ids
    @technical_roles_ids ||= Role.where(technical: true).pluck(:id)
  end
end
