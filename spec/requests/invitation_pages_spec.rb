require 'spec_helper'

describe "Invitations" do
  let(:admin) { create(:admin_user) }
  let!(:ac_user) { create(:user) }
  let!(:ac) { create(:associate_consultant, :user => ac_user) }
  let!(:review) { create(:review, associate_consultant: ac) }
  let(:invited_user) { create(:user, :email => "invited@thoughtworks.com") }
  let(:uninvited_user) { create(:user, :email => "uninvited@thoughtworks.com") }

  subject { page }

  describe "invitation form", :js => true do

    context "as ac" do
      before do
        ActionMailer::Base.deliveries.clear
        sign_in ac_user
        visit new_review_invitation_path(review)
        find(".TokenSearch input").native.send_keys("reviewer@thoughtworks.com,")
        fill_in "message", with: "Why, hello!"
      end

      it "redirects to review after submission", :focus => true do
        find("#send-request").click
        current_path.should == review_path(review)
        page.should have_selector('.flash-success')
      end

      it "sends an invitation email" do
        UserMailer.should_receive(:review_invitation).and_return(double(deliver: true))
        find("#send-request").click
      end

      it "sends an invitation email and a copy to the AC" do
        find(:css, "#copy_sender").set(true)
        UserMailer.should_receive(:review_invitation).and_return(double(deliver: true))
        UserMailer.should_receive(:review_invitation_AC_copy).and_return(double(deliver: true))

        find("#send-request").click
      end

      it "only lists successful emails in copy sent to AC" do
        find(".TokenSearch input").native.send_keys("reviewer1@thoughtworks.com, reviewer2,")
        find(:css, "#copy_sender").set(true)

        find("#send-request").click
        ActionMailer::Base.deliveries.count.should eq 3
        ActionMailer::Base.deliveries.map { |email| email.to }.flatten.should =~
            ["reviewer@thoughtworks.com","reviewer1@thoughtworks.com",ac_user.email]
      end

      it "should not send a copy of the invitation email to the AC if checkbox isn't selected" do
        find("#send-request").click
        ActionMailer::Base.deliveries.count.should eq 1
      end
    end

    describe "as an ac" do
      context "when I invite someone for feedback" do
        let(:additional_email) { "anextraemail@thoughtworks.com" }

        before do
          create(:additional_email, email: additional_email,
                 user_id: invited_user.id)
          sign_in ac_user
          visit new_review_invitation_path(review)
          find(".TokenSearch input").native.send_keys(additional_email, ",")
          fill_in "message", with: "Why, hello!"
          find("#send-request").click
        end
        context "with an unconfirmed email alias" do
          it "should not display a feedback request" do
            sign_in invited_user
            visit feedbacks_user_path(invited_user)

            page.should_not have_content(ac_user.name)
          end
        end

        context "with a confirmed email alias" do
          it "should display a feedback request" do
            extra_email = AdditionalEmail.find_by_email(additional_email)
            extra_email.confirmed_at = Date.today
            page.should have_content(ac_user.name)
          end
        end
      end
    end

    context "as other user" do
      it "should not be accessible to other users" do
        other_user = create(:user)
        sign_in other_user
        visit new_review_invitation_path(review)
        page.should have_content "You are not authorized to access this page!"
      end
    end

    context "as invited user" do
      let!(:invitation) { create(:invitation, :review => review, :email => "invited@thoughtworks.com") }

      it "should let user decline invitation" do
        sign_in invited_user
        visit feedbacks_user_path(invited_user)
        expect do
          find("a[href^=\"" + review_invitation_path(review, invitation) + "\"]").click
          page.driver.browser.switch_to.alert.accept
          page.find(".flash-success").text.should include "You have successfully declined #{ac_user.name}'s feedback request."
        end.to change(Invitation, :count).by(-1)
      end
    end
  end
end
