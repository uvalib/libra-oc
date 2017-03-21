require_dependency 'libraoc/serviceclient/user_info_client'
require_dependency 'libraoc/serviceclient/orcid_access_client'
require_dependency 'libraoc/helpers/user_info'

module Helpers

  def lookup_user( id )

    status, resp = ServiceClient::UserInfoClient.instance.get_by_id( id )
    if ServiceClient::UserInfoClient.instance.ok?( status )
      return Helpers::UserInfo.create( resp )
    end
    return nil

  end

  # get the authors ORCID when given a work
  def lookup_orcid( cid )
    return '' if cid.blank?

    status, orcid = ServiceClient::OrcidAccessClient.instance.get_by_cid( cid )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      return orcid
    else
      puts "INFO: No ORCID located for #{cid}" if status == 404
      puts "ERROR: ORCID lookup returns #{status}" unless status == 404
    end

    # no ORCID found
    return ''

  end

end

#
# end of file
#