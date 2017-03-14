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
    delegate :contributors, to: :model

    def self.multiple?(field)

      if [:title, :description, :publisher, :source, :abstract].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_)
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      attrs[:description] = Array(attrs[:description]) if attrs[:description]
      attrs[:source] = Array(attrs[:source]) if attrs[:source]
      #attrs[:abstract] = Array(attrs[:abstract]) if attrs[:abstract]
      attrs
    end

    def title
      super.first || ""
    end

    def description
      super.first || ""
    end

    #def abstract
    #  super.first || ""
    #end


    def source
      super.first || ""
    end

    def authors
      model.authors.any? ? model.authors : [model.authors.build]
    end

    def authors_attributes= attributes
      model.authors_attributes= attributes
    end

    def contributors
      model.contributors.any? ? model.contributors : [model.contributors.build]
    end

    def contributors_attributes= attributes
      model.contributors_attributes= attributes
    end

    protected

    def self.build_permitted_params
      permitted = super
      permitted.delete( {authors: []} )
      permitted << { authors_attributes: permitted_people_params }
      permitted.delete( {contributors: []} )
      permitted << { contributors_attributes: permitted_people_params }
      permitted << :rights
      permitted
    end

    def self.permitted_people_params
      [ :id, :_destroy, :first_name, :last_name, :computing_id, :institution, :department ]
    end

  end
end
