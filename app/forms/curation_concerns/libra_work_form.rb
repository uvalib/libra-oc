# Generated via
#  `rails generate curation_concerns:work LibraWork`
module CurationConcerns
  class LibraWorkForm < Sufia::Forms::WorkForm
    self.model_class = ::LibraWork
    self.required_fields += [:authors]
    self.required_fields -= [:creator]
    self.terms += [:resource_type, :abstract, :authors, :contributors]
    self.terms -= [:description, :creator, :subject, :based_near, :contributor]
    delegate :authors, to: :model

    def self.multiple?(field)

      if [:title, :description, :publisher, :source].include? field.to_sym
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
      attrs[:source] = Array(attrs[:source]) if attrs[:source]
      attrs[:abstract] = Array(attrs[:abstract]) if attrs[:abstract]
      attrs
    end

    def title
      super.first || ""
    end

    def description
      super.first || ""
    end

    def abstract
      super.first || ""
    end

    def publisher
      super.first || ""
    end

    def source
      super.first || ""
    end

    def authors
      model.authors.any? ? model.authors : [model.authors.build]
    end

    def authors_attributes= attributes
      model.authors_attributes= attributes
    end

    protected

    def self.build_permitted_params
      permitted = super
      permitted.delete( {authors: []} )
      permitted << { authors_attributes: permitted_authors_params }
      permitted << :rights
      permitted
    end

    def self.permitted_authors_params
      [ :id, :_destroy, :first_name, :last_name, :computing_id, :institution, :department ]
    end

  end
end
