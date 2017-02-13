class Author < ActiveFedora::Base
  type ::RDF::Vocab::FOAF.Person

  has_many :libra_works

  has_many :generic_files, inverse_of: :authors, class_name: "GenericFile"

  property :first_name, predicate: ::RDF::Vocab::FOAF.firstName, multiple: false do |index|
    index.as :stored_searchable
  end

  property :last_name, predicate: ::RDF::Vocab::FOAF.lastName, multiple: false do |index|
    index.as :stored_searchable
  end
end
