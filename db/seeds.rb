require 'factory_girl'
require 'faker'

require './db/seeds/skills_and_categories'

billable_roles = %w(senior developer)
non_billable_roles = %w(junior praktykant pm junior\ pm qa junior\ qa talent)
technical_roles = %w(junior praktykant developer senior)
contract_types = %w(DG UoP UoD)
locations = %w(Poznan Warsaw Gdansk Zielona\ Gora Krakow Remotely Wroclaw Bialystok).sort

billable_roles.each do |name|
  Role.find_or_create_by(name: name).update_attribute(:billable, true)
end

non_billable_roles.each do |name|
  Role.find_or_create_by(name: name).update_attribute(:billable, false)
end

technical_roles.each do |name|
  Role.find_or_create_by(name: name).update_attribute(:technical, true)
end

contract_types.each do |name|
  ContractType.find_or_create_by(name: name)
end

locations.each do |name|
  Location.find_or_create_by(name: name)
end

Membership.where(billable: nil).each do |membership|
  billable = membership.try(:role).try(:billable) || false
  membership.update_attribute(:billable, billable)
end

FactoryGirl.create_list(:user, 50) if Rails.env.development?

