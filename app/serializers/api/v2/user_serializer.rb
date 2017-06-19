module Api::V2
  class UserSerializer < ActiveModel::Serializer
    attributes :uid, :email, :first_name, :last_name, :gh_nick, :archived, :primary_roles, :role,
      :primary_role, :salesforce_id

    has_many :memberships, serializer: MembershipSerializer

    def memberships
      object.memberships.group_by(&:project_id).map { |_key, value| value.last }
    end

    def role
      object.primary_role.try(:name)
    end
  end
end
