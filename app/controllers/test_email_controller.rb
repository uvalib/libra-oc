class TestEmailController < ApplicationController

  # GET /test_email
  def test_email
    TestMailer.email( EXCEPTION_RECIPIENTS, MAIL_SENDER, 'libra-oc test email' ).deliver_later
  end

end
