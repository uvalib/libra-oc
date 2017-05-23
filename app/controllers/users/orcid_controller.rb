class Users::OrcidController < ApplicationController

  def landing
    orcid_response = orcid_token_exchange
    body = JSON.parse orcid_response.body
    if orcid_response.code == 200
      redirect_to root_url, notice: "Your ORCID account info was received ----- #{body}"
    else
      redirect_to root_url, alert: "There was an error linking your ORCID account ----- #{body}"
    end
  end

  private
  def orcid_token_exchange
    begin
    RestClient.post('https://orcid.org/oauth/token', {
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
