module Libraoc::PersonMetadata
  extend ActiveSupport::Concern

  class_methods do
    def sort unsorted_array
      unsorted_array.sort {|a,b| a.index <=> b.index}
    end
  end

  included do

    type ::RDF::Vocab::FOAF.Person

    property :index, predicate: ::RDF::URI.new('http://libra.virginia.edu/index'), multiple: false do |index|
      index.as :sortable
    end

    property :first_name, predicate: ::RDF::Vocab::SCHEMA.givenName, multiple: false do |index|
      index.as :stored_searchable
    end

    property :last_name, predicate: ::RDF::Vocab::SCHEMA.familyName, multiple: false do |index|
      index.as :stored_searchable
    end

    property :computing_id, predicate: ::RDF::Vocab::SCHEMA.email, multiple: false do |index|
      index.as :stored_searchable
    end

    property :department, predicate: ::RDF::Vocab::SCHEMA.department, multiple: false do |index|
      index.as :stored_searchable
    end

    property :institution, predicate: ::RDF::Vocab::SCHEMA.affiliation, multiple: false do |index|
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
