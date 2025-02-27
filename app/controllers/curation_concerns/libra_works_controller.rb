# Generated via
#  `rails generate curation_concerns:work LibraWork`

module CurationConcerns
  class LibraWorksController < ApplicationController

    include CurationConcerns::CurationConcernController
    include Sufia::WorksControllerBehavior

    include WorkHelper

    self.curation_concern_type = LibraWork
    self.show_presenter = LibraWorkPresenter

    after_action :new_files_notice, only: [:create, :update]
    after_action :update_orcid, only: [:create, :update]

    def new
      super

      # pre-fill first author with current user
      status, resp = ServiceClient::UserInfoClient.instance.get_by_id( current_user.computing_id )
      if ServiceClient::UserInfoClient.instance.ok?( status )
        @form.model.authors.build(
          computing_id: current_user.computing_id,
          first_name: resp['first_name'],
          last_name: resp['last_name'],
          department: resp['department'] ? resp['department'].first : '',
          institution: resp['institution'].blank? ? LibraWork::DEFAULT_INSTITUTION : resp['institution']
        )
      end
    end

    def update

      # snapshot of the work before updating
      work_before = WorkAuditJob.serialize_work( get_work_item( params['id'] ) )

      @depositorBefore = curation_concern.depositor

      # call base class for actual update behavior
      super

      # kick off the work audit task
      work_after = WorkAuditJob.serialize_work( get_work_item( params['id'] ) )
      WorkAuditJob.perform_later( current_user, work_before, work_after )

      # kick off the file auditing task
      FileAddedAuditJob.perform_later( current_user, work_before, work_after, params['uploaded_files'] ) unless params['uploaded_files'].blank?
    end

    protected
    def after_update_response
      # edit_users needs to be updated because Libra doesn't use the built-in permission pages.
      # depositor owns the work and access needs to be updated when that changes
      if @depositorBefore != curation_concern.depositor
        curation_concern.edit_users = [curation_concern.depositor]
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

    def update_orcid
      OrcidSyncJob.perform_later @curation_concern.id, current_user.id
    end

  end
end
