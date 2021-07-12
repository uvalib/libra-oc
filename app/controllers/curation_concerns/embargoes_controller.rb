class EmbargoesController < ApplicationController
  include CurationConcerns::EmbargoesControllerBehavior

  # Removes a single embargo
  def destroy
    CurationConcerns::Actors::EmbargoActor.new(curation_concern).destroy

    # Removed the file permission confirmation screen since files always have the same permissions.
    # Instead apply the permissions from sufia/app/controllers/curation_concerns/permissions_controller.rb
    authorize! :edit, curation_concern
    # copy visibility
    VisibilityCopyJob.perform_later(curation_concern)

    # copy permissions
    InheritPermissionsJob.perform_later(curation_concern)
    redirect_to [main_app, curation_concern], notice: curation_concern.embargo_history.last
  end
end