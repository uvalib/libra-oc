require_dependency 'libraoc/serviceclient/orcid_access_client'

module Libraoc::OrcidBehavior

    extend ActiveSupport::Concern

    included do
      after_save :save_orcid, :if => :orcid_changed?
    end

    private

    #
    # save an updated value
    #
    def save_orcid
      update_orcid_service( User.cid_from_email( email ), orcid.gsub( 'http://orcid.org/', '' ) )
    end

    #
    # update the ORCID service with the fact that we have a CID/ORCID association
    #
    def update_orcid_service( cid, orcid )
      return if cid.blank?

      # do we have an orcid to update
      if orcid.blank? == false
         puts "==> setting #{cid} ORCID to: #{orcid}"
         status = ServiceClient::OrcidAccessClient.instance.set_by_cid( cid, orcid )
      else
        puts "==> clearing #{cid} ORCID"
        status = ServiceClient::OrcidAccessClient.instance.del_by_cid( cid )
      end

      if ServiceClient::OrcidAccessClient.instance.ok?( status ) == false
        puts "ERROR: ORCID service returns #{status}"
      end
    end
end
