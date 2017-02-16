# Generated via
#  `rails generate curation_concerns:work LibraWork`

module CurationConcerns
  class LibraWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = LibraWork

    def save
      super
    end
  end
end
