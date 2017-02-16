require_dependency 'libraoc/serviceclient/user_info_client'
require_dependency 'libraoc/helpers/user_info'

module Helpers

  def lookup_user( id )

    status, resp = ServiceClient::UserInfoClient.instance.get_by_id( id )
    if ServiceClient::UserInfoClient.instance.ok?( status )
      return Helpers::UserInfo.create( resp )
    end
    return nil

  end

end

#
# end of file
#