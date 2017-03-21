# Generated via
#  `rails generate curation_concerns:work LibraWork`
class LibraWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include Libraoc::BasicMetadata
  include Sufia::WorkBehavior
  self.human_readable_type = 'Work'

    # specify the indexer used to create the SOLR document
  def self.indexer
    LibraOcIndexer
  end

  # defaults
  DEFAULT_INSTITUTION = 'University of Virginia'.freeze
  DEFAULT_PUBLISHER = DEFAULT_INSTITUTION
  DEFAULT_LICENSE = 'None'.freeze
  DEFAULT_LANGUAGE = 'English'.freeze

  # embargo periods (only one)
  EMBARGO_VALUE_FOREVER = 'forever'.freeze

  has_and_belongs_to_many :authors, predicate: ::RDF::Vocab::DC.creator,
    class_name: 'Author', inverse_of: :libra_works
  accepts_nested_attributes_for :authors

  has_and_belongs_to_many :contributors, predicate: ::RDF::Vocab::DC.contributor,
    class_name: 'Contributor', inverse_of: :libra_works
  accepts_nested_attributes_for :contributors

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
#  validates :title, presence: { message: 'Your work must have a title.' }
#  validates :abstract, presence: { message: 'Your work must have an abstract.' }
# validates :publisher, presence: { message: 'Your work must have a publisher.' }
# validates :resource_type, presence: { message: 'Your work must have a Resource Type.' }
# validates :license, presence: { message: 'Your work must have a license.' }


  property :abstract, predicate: ::RDF::Vocab::DC.abstract, multiple: false do |index|
    index.as :stored_searchable
  end


  property :published_date, predicate: ::RDF::Vocab::SCHEMA.datePublished, multiple: false do |index|
    index.as :stored_searchable
  end

  property :sponsoring_agency, predicate: ::RDF::Vocab::SCHEMA.funder do |index|
    index.as :stored_searchable
  end

  property :notes, predicate: ::RDF::Vocab::SCHEMA.comment, multiple: false do |index|
    index.type :text
    index.as :stored_searchable
  end

  property :license, predicate: ::RDF::Vocab::DC.rights, multiple: false do |index|
    index.as :stored_searchable
  end

  property :doi, predicate: ::RDF::Vocab::Identifiers.orcid, multiple: false do |index|
    index.as :stored_searchable
  end

  property :libra_id, predicate: ::RDF::Vocab::Identifiers.local, multiple: false do |index|
    index.as :stored_searchable
  end

  property :work_source, predicate: ::RDF::URI('http://example.org/terms/work_source'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :admin_notes, predicate: ::RDF::URI('http://example.org/terms/admin_notes') do |index|
    index.type :text
    index.as :stored_searchable
  end


end
