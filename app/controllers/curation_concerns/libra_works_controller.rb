# Generated via
#  `rails generate curation_concerns:work LibraWork`

module CurationConcerns
  class LibraWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    include Sufia::WorksControllerBehavior
    include SufiaWorksOverrides

    self.curation_concern_type = LibraWork
    self.show_presenter = LibraWorkPresenter

    def new
      super

      # pre-fill first author with current user
      status, resp = ServiceClient::UserInfoClient.instance.get_by_id( current_user.computing_id )
      if ServiceClient::UserInfoClient.instance.ok?( status )
        @form.model.authors.build(
          computing_id: current_user.computing_id,
          first_name: resp['first_name'],
          last_name: resp['last_name'],
          department: resp['department'],
          institution: resp['institution'].blank? ? LibraWork::DEFAULT_INSTITUTION : resp['institution']
        )
      end
    end
  end
end
