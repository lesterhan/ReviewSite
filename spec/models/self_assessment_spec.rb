require 'spec_helper'

describe SelfAssessment do

  before do
    @self_assessment =  SelfAssessment.new
    @self_assessment.review = create(:review)
    @self_assessment.associate_consultant = create(:associate_consultant)
  end

  it "requires an ac" do
    @self_assessment.valid?.should == false
    @self_assessment.response = "stuff"
    @self_assessment.valid?.should == true
  end

  it "requires a review" do
    @self_assessment.valid?.should == false
    @self_assessment.response = "stuff"
    @self_assessment.valid?.should == true
  end

  it "requires a response" do
    @self_assessment.response = nil
    @self_assessment.valid?.should == false
  end

  it "before the review deadline" do
    @self_assessment.review.review_date = Date.today + 5.days
    @self_assessment.review_happened_recently?.should == false
  end

  it "within two weeks of the review deadline's passing" do
    @self_assessment.review.review_date = Date.today - 5.days
    @self_assessment.review_happened_recently?.should == true
  end

  it "when it's been more than two weeks after the review deadline" do
    @self_assessment.review.review_date = Date.today - (2.weeks + 1.day)
    @self_assessment.review_happened_recently?.should == false
  end
end
