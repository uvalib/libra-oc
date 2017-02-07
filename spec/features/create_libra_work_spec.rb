# Generated via
#  `rails generate curation_concerns:work LibraWork`
require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a LibraWork' do
  context 'a logged in user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      login_as user
    end

    scenario do
      visit new_curation_concerns_libra_work_path
      fill_in 'Title', with: 'Test LibraWork'
      click_button 'Create LibraWork'
      expect(page).to have_content 'Test LibraWork'
    end
  end
end
