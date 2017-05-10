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
    per_page = 15
    params[:max] = per_page
    @page = params[:page].to_i

    if @page
      params[:start] = @page * per_page
      @next_page = @page + 1
      @prev_page = @page - 1
    else
      params[:start] = '0'
      @next_page = 1
    end

    status, resp = ServiceClient::OrcidAccessClient.instance.search( params[:q], params[:start], params[:max] )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
    else
      resp = []
    end

    respond_to do |wants|
      wants.json {
        render json: resp, status: :ok
      }
      wants.html {
        @orcid_profiles = resp
        @q = params[:q]
        @next_page = nil if @orcid_profiles.count < per_page
        @prev_page = nil if @prev_page < 0

        render 'users/orcid_results', layout: false
      }
    end
  end

end
