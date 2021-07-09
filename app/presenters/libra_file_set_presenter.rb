require_dependency 'app/helpers/permissions_helper'

class LibraFileSetPresenter < Sufia::FileSetPresenter

  include PermissionsHelper

  def libra_permission_badge
    permission_label( self.solr_document.visibility )
  end

end