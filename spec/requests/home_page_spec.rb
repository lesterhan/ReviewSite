require 'spec_helper'

describe "Home page" do
  let! (:jc) { FactoryGirl.create :junior_consultant }
  let! (:review) { FactoryGirl.create :review, junior_consultant: jc }

  subject { page }

  describe "logged in as Admin" do
    let (:admin) { FactoryGirl.create :admin_user }
    before { sign_in admin }

    it "can navigate to the reviewer invitation page" do
      click_link 'Invite Reviewer'
      page.should have_selector('h1', text: 'Invite Reviewer')
    end
  end

  describe "logged in as a JC" do
    let (:jc_user) { FactoryGirl.create :user, email: jc.email }
    before { sign_in jc_user }

    it "can navigate to the reviewer invitation page" do
      click_link 'Invite Reviewer'
      page.should have_selector('h1', text: 'Invite Reviewer')
    end

    it "does not show feedback count when not submitted" do
      feedback = FactoryGirl.create(:feedback, 
                                    :review => review, 
                                    :user => jc_user, 
                                    :project_worked_on => "Unsubmitted Feedback")
      visit root_path
      page.should have_selector('td', text: '0')
    end

    it "shows the count of submitted feedbacks" do
      feedback = FactoryGirl.create(:submitted_feedback, 
                                    :review => review, 
                                    :user => jc_user, 
                                    :project_worked_on => "Submitted Feedback")
      visit root_path
      page.should have_selector('td', text: '1')
    end
  end
end