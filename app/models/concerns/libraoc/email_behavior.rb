module Libraoc::EmailBehavior

  extend ActiveSupport::Concern

  included do

    # status of emails associated with this work
    EMAIL_STATUS_SENT_NONE = 0
    EMAIL_STATUS_SENT_DEPOSITOR = 1

    after_save :determine_email_behavior

    property :email_status, predicate: ::RDF::URI('http://example.org/terms/email_status'), multiple: false

    private

    def determine_email_behavior

      # set initial state if it is undefined
      self.email_status = EMAIL_STATUS_SENT_NONE if self.email_status.nil?

      # time for an email?
      if depositor_email_pending?
        WorkMailer.public_work_submitted( self, self.depositor, MAIL_SENDER ).deliver_later
        set_depositor_email_status( true )
        self.save!
      end

    end

    #
    # have we sent the depositor a success email yet?
    #
    def depositor_email_pending?

      # no emails for private content
      return false if is_private?

      # no emails for migrated content
      return false if is_legacy_content?

      # no duplicate emails...
      return false if ( self.email_status & EMAIL_STATUS_SENT_DEPOSITOR ) == EMAIL_STATUS_SENT_DEPOSITOR

      # send an email
      return true
    end

    #
    # update the email status for the depositor email
    #
    def set_depositor_email_status( sent )
      self.email_status = self.email_status | EMAIL_STATUS_SENT_DEPOSITOR if sent
      self.email_status = self.email_status ~ EMAIL_STATUS_SENT_DEPOSITOR unless sent
    end

  end

end