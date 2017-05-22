# Generated via
#  `rails generate curation_concerns:work LibraWork`
class LibraWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include Libraoc::BasicMetadata
  include Sufia::WorkBehavior
  include UrlHelper

  # first time create behavior
  include Libraoc::CreateBehavior

  # support for assignment of published date
  include Libraoc::PublishBehavior

  # support for allocation of DOI
  include Libraoc::DoiBehavior

  # support to manage email state
  include Libraoc::EmailBehavior

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

  # source definitions
  SOURCE_LEGACY = 'libra-oa'.freeze

  has_and_belongs_to_many :authors, predicate: ::RDF::Vocab::DC.creator,
    class_name: 'Author', inverse_of: :libra_works
  accepts_nested_attributes_for :authors, reject_if: all_blank_except(:index), allow_destroy: true

  has_and_belongs_to_many :contributors, predicate: ::RDF::Vocab::DC.contributor,
    class_name: 'Contributor', inverse_of: :libra_works
  accepts_nested_attributes_for :contributors, reject_if: all_blank_except(:index), allow_destroy: true

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
#  validates :title, presence: { message: 'Your work must have a title.' }
#  validates :abstract, presence: { message: 'Your work must have an abstract.' }
# validates :publisher, presence: { message: 'Your work must have a publisher.' }
# validates :resource_type, presence: { message: 'Your work must have a Resource Type.' }
# validates :license, presence: { message: 'Your work must have a license.' }

  before_save :format_admin_notes


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

  #
  # is this work publicly visible?
  #
  def is_publicly_visible?
    return false if visibility.nil?
    return( visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC )
  end

  #
  # is this work visible within the institution?
  #
  def is_institution_visible?
    return false if visibility.nil?
    return( visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED )
  end

  #
  # is this work private to the depositor?
  #
  def is_private?
    return true if visibility.nil?
    return( visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE )
  end

  #
  # is this content mine according to the depositor?
  #
  def is_mine?( me )
    return false if me.nil?
    return false if depositor.nil?
    return depositor == me
  end

  #
  # is this legacy (migrated) content?
  #
  def is_legacy_content?
    return false if work_source.nil?
    return work_source.start_with? LibraWork::SOURCE_LEGACY
  end

  #
  # Thumbnail url for solr
  #
  def thumbnail_url
    # Just show defaults for now
    ActionController::Base.helpers.image_url 'default.png', host: public_site_url

    # Actual thumbnails are ready to go below.
    #if self.thumbnail.present?
    #  Rails.application.routes.url_helpers.download_url(self.thumbnail.id, file: 'thumbnail')
    #else
    #  ActionController::Base.helpers.image_url 'default.png'
    #end
  end

  def format_admin_notes

    # A UTF8 minus sign
    date_marker = "\u{2212}"

    formatted_admin_notes = admin_notes.map do |an|
      if an.include? date_marker
        an
      else
        date = DateTime.now.strftime "%F %R #{date_marker} "

        date + an
      end
    end
    self.admin_notes = formatted_admin_notes.compact.sort
  end

end
