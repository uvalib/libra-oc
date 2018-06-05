# Generated via
#  `rails generate hyrax:work LibraWork`
module Hyrax
  class LibraWorkForm < Hyrax::Forms::WorkForm
    self.model_class = ::LibraWork
    self.terms -= [:description, :creator, :subject, :based_near, :contributor,
                   :keyword, :publisher, :date_created, :identifier,
                   :related_url, :source ]
    self.terms += [ :resource_type, :abstract, :authors,
                    :keyword, :contributors, :source_citation, :publisher, :published_date,
                    :related_url, :sponsoring_agency, :notes, :admin_notes
    ]
    self.required_fields = [:resource_type, :title, :authors, :abstract, :rights]
    delegate :authors, to: :model
    delegate :contributors, to: :model
    delegate :admin_notes, to: :model
    attr_reader :has_existing_files, :is_admin

    def initialize(model, current_ability)
      super
      @agreement_accepted = !model.new_record? && !(model.visibility == 'restricted' && model.doi.nil?)
    end

    def self.multiple?(field)

      if [:title, :publisher, :abstract, :source_citation].include? field.to_sym
        false
      else
        super
      end
    end

    def self.model_attributes(_)
      attrs = super
      attrs[:title] = Array(attrs[:title]) if attrs[:title]
      #attrs[:description] = Array(attrs[:description]) if attrs[:description]
      #attrs[:abstract] = Array(attrs[:abstract]) if attrs[:abstract]
      attrs
    end

    def title
      super.first || ""
    end

    def description
      super.first || ""
    end

    def publisher
      super.present? ? super : LibraWork::DEFAULT_PUBLISHER
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

    def private_visibility_disabled?
      ( model.id.present? && !model.private_access? && !current_ability.current_user.admin?)
    end


    protected

    def self.build_permitted_params
      permitted = super
      permitted.delete( {authors: []} )
      permitted << { authors_attributes: permitted_people_params }
      permitted.delete( {contributors: []} )
      permitted << { contributors_attributes: permitted_people_params }
      permitted << :rights
      permitted << :language
      permitted << :resource_type
      permitted << :admin_notes
      permitted
    end

    def self.permitted_people_params
      [ :id, :_destroy, :first_name, :last_name, :computing_id, :institution, :department, :index, :orcid ]
    end

  end
end
