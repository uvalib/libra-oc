# Generated via
#  `rails generate curation_concerns:work LibraWork`
module CurationConcerns
  class LibraWorkForm < Sufia::Forms::WorkForm
    self.model_class = ::LibraWork
    self.terms += [:resource_type]

  end
end
