require_dependency 'libraoc/serviceclient/user_info_client.rb'
require_dependency 'libraoc/serviceclient/orcid_access_client.rb'

class AjaxController < ApplicationController

  # GET /computing_id
  def computing_id
    respond_to do |wants|
      wants.json {
        status, resp = ServiceClient::UserInfoClient.instance.get_by_id( params[:id] )
        if ServiceClient::UserInfoClient.instance.ok?( status )
          resp[:institution] = LibraWork::DEFAULT_INSTITUTION if resp[:institution].blank?
          resp[:index] = params[:index]
        else
          resp = { }
        end
        render json: resp, status: :ok
      }
    end
  end

  # GET /orcid_search
  def orcid_search
    respond_to do |wants|
      wants.json {
        params[:start] = '0' unless params[:start]
        params[:max] = '25' unless params[:max]
        status, resp = ServiceClient::OrcidAccessClient.instance.search( params[:q], params[:start], params[:max] )
        if ServiceClient::OrcidAccessClient.instance.ok?( status )
        else
          resp = { }
        end
        render json: resp, status: :ok
      }
    end
  end

end