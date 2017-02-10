# Generated via
#  `rails generate curation_concerns:work LibraWork`
module CurationConcerns
  class LibraWorkForm < Sufia::Forms::WorkForm
    self.model_class = ::LibraWork
    self.required_fields -= [:creator]
    self.terms += [:resource_type, :abstract]
    self.terms -= [:description, :creator, :subject]

    def self.multiple?(field)
      if [:title, :description, :publisher, :rights, :source].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_)
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      attrs[:description] = Array(attrs[:description]) if attrs[:description]
      attrs[:publisher] = Array(attrs[:publisher]) if attrs[:publisher]
      attrs
    end

    def title
      super.first || ""
    end

    def description
      super.first || ""
    end

    def publisher
      super.first || ""
    end

    def rights
      super.first || ""
    end

    def source
      super.first || ""
    end

  end
end
