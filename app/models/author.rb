class Author < ActiveFedora::Base
  type ::RDF::Vocab::FOAF.Person

  has_many :libra_works, inverse_of: :authors

  property :first_name, predicate: ::RDF::Vocab::FOAF.firstName, multiple: false do |index|
    index.as :stored_searchable
  end

  property :last_name, predicate: ::RDF::Vocab::FOAF.lastName, multiple: false do |index|
    index.as :stored_searchable
  end

  property :computing_id, predicate: ::RDF::URI('http://example.org/terms/work_type'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :department, predicate: ::RDF::URI('http://example.org/terms/work_type'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :institution, predicate: ::RDF::URI('http://example.org/terms/work_type'), multiple: false do |index|
    index.as :stored_searchable
  end

end
