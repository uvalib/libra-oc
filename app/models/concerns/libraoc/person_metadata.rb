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
  end

end
