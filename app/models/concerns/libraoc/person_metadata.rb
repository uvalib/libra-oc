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
    # helper to allow us to display Person information in a consistent manner
    #
    def to_s
      if self.computing_id.present?
        return User.email_from_cid( self.computing_id )
      end

      if self.first_name.present? && self.last_name.present?
        return "#{self.first_name} #{self.last_name}"
      end

      return 'Unknown'
    end
  end

end
