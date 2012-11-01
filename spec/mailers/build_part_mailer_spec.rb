require "spec_helper"

describe BuildPartMailer do
  let(:build) { FactoryGirl.create(:build, :queue => :developer) }

  describe "#time_out_email" do
    it "sends the email" do
      build_part = build.build_parts.create!(:paths => ["a", "b"], :kind => "cucumber")
      build_part.build_attempts.build(:state => :errored, :builder => "test-builder")

      email = BuildPartMailer.time_out_email(build_part)
      email.to.should include(BuildPartMailer::NOTIFICATIONS_EMAIL)
      email.body.should include("test-builder")
      email.body.should include("http://")
    end
  end

  describe "#build_break_email" do
    before do
      GitBlame.stub(:changes_since_last_green).and_return([{:hash => "sha", :author => "Joe", :date => "some day", :message => "always be shipping it"}])
      GitBlame.stub(:emails_since_last_green).and_return(["foo@example.com"])
    end

    it "sends the email" do
      build_part = build.build_parts.create!(:paths => ["a", "b"], :kind => "cucumber")
      build_attempt = build_part.build_attempts.create!(:state => :failed, :builder => "test-builder")

      email = BuildPartMailer.build_break_email(build)

      email.to.should == ["foo@example.com"]

      email.bcc.should include(BuildPartMailer::NOTIFICATIONS_EMAIL)
      email.html_part.body.should include(build_part.project.name)
      email.text_part.body.should include(build_part.project.name)
      email.html_part.body.should include("http://")
      email.text_part.body.should include("http://")
    end
  end
end
