require_dependency 'app/helpers/permissions_helper'

class LibraFileSetPresenter < Hyrax::FileSetPresenter

  include PermissionsHelper

  def libra_permission_badge
    permission_label( self.solr_document )
  end

end
