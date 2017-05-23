require 'socket'

module UrlHelper

  def fully_qualified_work_url( id )
    "#{public_site_url}#{locally_hosted_work_url( id )}"
  end

  def locally_hosted_work_url( id )
    "/public_view/#{id}"
  end

  def public_site_url
    return "#{protocol}://#{hostname}"
  end

  def orcid_oauth_url
    redirect = Rails.application.routes.url_helpers.orcid_landing_url
    orcid_client_id = ENV['ORCID_CLIENT_ID']

    "https://orcid.org/oauth/authorize?client_id=#{orcid_client_id}&response_type=code&scope=/authenticate&redirect_uri=#{redirect}"

  end

  private

  def hostname
    return Socket.gethostname unless Rails.env.development?
    return 'localhost:3000'
  end

  def protocol
    return 'https' unless Rails.env.development?
    return 'http'
  end
end
