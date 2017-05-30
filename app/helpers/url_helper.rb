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

  def orcid_oauth_button
    redirect = Rails.application.routes.url_helpers.orcid_landing_url
    orcid_client_id = ENV['ORCID_CLIENT_ID']

    # eventually add ' /activities/update' to scope
    button_html = link_to "#{ENV['ORCID_BASE_URL']}/oauth/authorize?client_id=#{orcid_client_id}&response_type=code&scope=/authenticate&redirect_uri=#{redirect}",
      id: 'connect-orcid-button', rel: 'nofollow' do
      image_tag('orcid.png') + " Create or Connect Your ORCID ID"
    end
    more_info_html = tag(:br) + link_to("Learn more about ORCID", 'https://orcid.org/content/about-orcid',
      target: '_blank')

    concat button_html
    concat more_info_html

    # concat already renders to the page so we dont want to return anything here
    nil
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
