require 'spec_helper'

describe "Password reset pages" do
  subject { page }

  let(:user) { FactoryGirl.create(:user, password_digest: BCrypt::Password.create("password")) }

  describe "Request password reset" do
    describe "request form" do
      before do
        visit root_path

        within "#okta-input" do
          fill_in "temp-okta", with: "askjdh"
          click_button "Change User"
        end

        click_button "Change User"
        visit signin_path
        click_link "Forgot password?"
      end

      it { title.should == 'Review Site | Request Password Reset' }

      describe "with invalid information" do
        before { click_button "Request Password Reset" }

        it { should have_selector('h1', text:'Sign In') }
        it { should have_selector('.flash-notice') }
      end

      describe "with valid information" do
        before { fill_in "Email", with: user.email }

        it "should send email when form is submitted" do
          UserMailer.should_receive(:password_reset).with(user).and_return(double("mailer", :deliver => true))
          click_button "Request Password Reset"

          should have_selector('h1', text:'Sign In')
          should have_selector('.flash-notice')
        end

        describe "when the user signs in" do
          before do
            click_button "Request Password Reset"
          end

          it "user should still have original password" do
            fill_in "Password", with: "password"
            fill_in "Email", with: user.email
            click_button "Sign In"

            page.should_not have_selector('.flash-error')
          end

        end
      end
    end

    describe "Create new password" do
      before do
        visit new_password_reset_path
        fill_in "Email", with: user.email
        click_button "Request Password Reset"
        user.reload
      end

      describe "with invalid token" do
        it "should go nowhere" do
          expect{ visit edit_password_reset_path(" ") }.to raise_error
        end
      end

      describe "with expired token" do
        before do
          user.update_attribute(:password_reset_sent_at, 3.hours.ago)
          visit edit_password_reset_path(user.password_reset_token)
        end

        it "should redirect to the new password reset form" do
          page.should have_selector('.flash')
          current_path.should == new_password_reset_path
        end
      end

      describe "with valid token" do
        before do
          visit edit_password_reset_path(user.password_reset_token)
        end

        it "should sign user is and redirect to homepage" do
          current_path.should == root_path
          user.reload
          user.okta_name.should == "person2"
        end
      end
    end
  end
end
