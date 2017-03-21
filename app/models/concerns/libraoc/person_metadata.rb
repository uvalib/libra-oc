module Libraoc::PersonMetadata
  extend ActiveSupport::Concern

  included do

    type ::RDF::Vocab::FOAF.Person

    property :first_name, predicate: ::RDF::Vocab::FOAF.firstName, multiple: false do |index|
      index.as :stored_searchable
    end

    property :last_name, predicate: ::RDF::Vocab::FOAF.lastName, multiple: false do |index|
      index.as :stored_searchable
    end

    property :computing_id, predicate: ::RDF::URI('http://example.org/terms/computing_id'), multiple: false do |index|
      index.as :stored_searchable
    end

    property :department, predicate: ::RDF::URI('http://example.org/terms/department'), multiple: false do |index|
      index.as :stored_searchable
    end

    property :institution, predicate: ::RDF::URI('http://example.org/terms/institution'), multiple: false do |index|
      index.as :stored_searchable
    end

    #
    # json encoded because this is what goes into solr.
    #
    def to_s
      self.to_json
    end

    #
    # helper to allow us to display Person information in a consistent manner
    #
    def to_display
      begin
        email = User.email_from_cid( self.computing_id )
        email = "(#{email})" if email.present?
        "#{self.first_name} #{self.last_name} #{email}"
      rescue
        'Unknown'
      end
    end
  end

end
