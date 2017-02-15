require_dependency 'libraoc/helpers/service_helpers'
include Helpers

module Libraoc::UserAttributes

  extend ActiveSupport::Concern

  included do

    def self.create_user( email )
      cid = cid_from_email( email )
      # lookup the user by computing id
      user_info = Helpers.lookup_user( cid )
      if user_info.nil?
        puts "ERROR: cannot locate user info for #{email}"
        return nil
      end
      return new_user( user_info, email )
    end

    # extract the computing ID from the supplied email address; assumes computing_id@blablabla.bla
    def self.cid_from_email( em )
       return '' if em.nil? || em.empty?
       return em.split( "@" )[ 0 ]
    end

    def self.email_from_cid( cid )
      return '' if cid.nil? || cid.empty?
      return "#{cid}@virginia.edu"
    end

    private

    def self.new_user( user_info, email )

      default_password = 'password'

      user = User.new( email: email,
                       password: default_password, password_confirmation: default_password,
                       display_name: user_info.display_name,
                       department: user_info.department,
                       office: user_info.office,
                       telephone: user_info.phone,
                       title: user_info.description )
      user.save!
      puts "STATUS: created new account for #{user_info.id}"
      return( user )

    end

  end

end