class UserSchedulingSerializer < ActiveModel::Serializer
  attributes :id, :gravatar, :primary_role, :name, :user_notes, :skill_ids, :rated_skill_ids, :rotation_class
  has_many :current_memberships, embed: :objects, serializer: MembershipSchedulingSerializer
  has_many :next_memberships, embed: :objects, serializer: MembershipSchedulingSerializer
  has_many :booked_memberships, embed: :objects, serializer: MembershipSchedulingSerializer

  def name
    "#{object.last_name} #{object.first_name}"
  end

  def primary_role
    role = object.primary_role
    { name: role.try(:name), id: role.try(:id) }
  end

  def rotation_class
    membership_start_date =
      if object.longest_current_membership
        object.longest_current_membership.starts_at
      else
        Date.current
      end

    months_in_project = (Date.current - membership_start_date.to_date) / 30.to_f
    return 'rotation-needed-danger' if months_in_project >= 8.0
    return 'rotation-needed-warning' if months_in_project >= 7.0
    return 'rotation-needed' if months_in_project >= 6.0
  end
end
