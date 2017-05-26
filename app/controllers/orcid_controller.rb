class OrcidController < ApplicationController

  def landing
    orcid_response = orcid_token_exchange
    body = JSON.parse orcid_response.body

    if orcid_response.code == 200 && current_user.update(orcid: body['orcid'])
      redirect_to root_url, notice: "Your ORCID account info was received ----- #{body}"
    else
      error = params['error_description'] || body
      redirect_to root_url, alert: "There was an error linking your ORCID account ----- #{error}"
    end
  end

  def destroy
    if current_user.update(orcid: nil)
      flash[:notice] = 'Your ORCID ID was successfully removed'
      redirect_to sufia.profile_path(current_user)
    else
      flash[:error] = 'The was a problem removing your ORCID ID'
      redirect_to sufia.edit_profile_path(current_user)
    end
  end

  private
  def orcid_token_exchange
    begin
    RestClient.post("#{ENV['ORCID_BASE_URL']}/oauth/token", {
        client_id: ENV['ORCID_CLIENT_ID'],
        client_secret: ENV['ORCID_CLIENT_SECRET'],
        grant_type: 'authorization_code',
        code: params['code'],
        redirect_uri: orcid_landing_url
      }, {accept: :json}
    )
    rescue RestClient::InternalServerError => e
      return e.response
    end
  end
end
