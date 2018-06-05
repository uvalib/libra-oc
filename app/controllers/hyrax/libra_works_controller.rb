# Generated via
#  `rails generate hyrax:work LibraWork`

module Hyrax
  class LibraWorksController < ApplicationController

    include Hyrax::WorksControllerBehavior
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
          department: resp['department'],
          institution: resp['institution'].blank? ? LibraWork::DEFAULT_INSTITUTION : resp['institution']
        )
      end
    end

    def update

      # snapshot of the work before updating
      work_before = WorkAuditJob.serialize_work( get_work_item( params['id'] ) )

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
      if permissions_changed? && curation_concern.file_sets.present?
        # Taken from Hyrax::PermissionsController
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
