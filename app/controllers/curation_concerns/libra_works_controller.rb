# Generated via
#  `rails generate curation_concerns:work LibraWork`

module CurationConcerns
  class LibraWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = LibraWork
    self.show_presenter = LibraWorkPresenter

    after_action :new_files_notice, only: [:create, :update]

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

    protected
    def after_update_response
      if permissions_changed? && curation_concern.file_sets.present?
        # Taken from CurationConcerns::PermissionsController
        # copy visibility
        VisibilityCopyJob.perform_later(curation_concern)
        # copy permissions
        InheritPermissionsJob.perform_later(curation_concern)
      end

      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern] }
        wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    private
    def new_files_notice
      if params.fetch(:uploaded_files, []).any?
        flash[:has_new_files] = true
      end
      flash[:notice] = nil
    end

  end
end
