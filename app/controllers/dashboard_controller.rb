class DashboardController < ApplicationController
  include Sufia::DashboardControllerBehavior
  include Blacklight::SearchHelper
  include ::UpdateOrcidBehavior

  before_action :sync_orcid_info

  def index
    @response, @docs = search_results( q: "#{Solrizer.solr_name( 'depositor' )}:#{current_user.email}",
                           sort: "#{Solrizer.solr_name('system_create', :stored_sortable, type: :date)} desc",                                    rows: 999 )



    super
  end

end
