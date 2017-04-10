# Generated via
#  `rails generate curation_concerns:work LibraWork`

module CurationConcerns
  class LibraWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = LibraWork
    self.show_presenter = LibraWorkPresenter

    def new
      curation_concern.publisher = LibraWork::DEFAULT_PUBLISHER if curation_concern.publisher.blank?
      super
    end

    def save
      super
    end

  end
end
