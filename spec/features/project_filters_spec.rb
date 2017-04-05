require 'spec_helper'

describe 'Project dashboard filters', js: true do
  let!(:admin_user) { create(:user, :admin, :developer) }
  let!(:dev_user) { create(:user, :admin, :developer, last_name: 'Developer', first_name: 'Daisy') }
  let!(:project_zztop) { create(:project, name: 'zztop') }
  let!(:project_test) { create(:project, name: 'test') }
  let!(:membership) { create(:membership, user: dev_user, project: project_test) }

  let(:projects_page) { App.new.projects_page }

  before(:each) do
    log_in_as admin_user
    projects_page.load
    wait_for_ajax
  end

  describe 'roles filter' do
    it 'shows all projects when empty string provided' do
      expect(projects_page).to have_text('zztop')
      expect(projects_page).to have_text('test')
    end

    it 'shows only matched projects when role is provided' do
      react_select('.filter.roles', membership.role.name)
      expect(projects_page).to_not have_text('zztop')
      expect(projects_page).to have_text('test')
    end
  end

  describe 'users filter' do
    it 'returns only matched projects when user name provided' do
      react_select('.filter.users', 'Developer Daisy')
      expect(projects_page).to have_text('test')
      expect(projects_page).to_not have_text('zztop')
    end

    it 'returns all projects when no selectize provided' do
      expect(projects_page).to have_text('zztop')
      expect(projects_page).to have_text('test')
    end

    context 'when user has not started a project' do
      let!(:junior_role) { create(:role, name: 'junior') }
      let!(:future_dev) { create(:user, primary_role: junior_role) }
      let!(:future_membership) do
        create(:membership, :future, user: future_dev, project: project_zztop)
      end

      it 'does not show the project' do
        visit '/dashboard/active'
        expect(projects_page).to have_text('zztop')
        wait_for_ajax
        react_select('.filter.users', future_dev.decorate.name)
        expect(page).to_not have_text('zztop')
      end
    end
  end

  describe 'projects filter' do
    it 'shows all projects when empty string provided' do
      expect(projects_page).to have_text('zztop')
      expect(projects_page).to have_text('test')
    end
  end
end
