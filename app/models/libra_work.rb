# Generated via
#  `rails generate curation_concerns:work LibraWork`
class LibraWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include Sufia::WorkBehavior
  self.human_readable_type = 'Work'

  has_and_belongs_to_many :authors, predicate: ::RDF::Vocab::DC.creator

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }
  validates :abstract, presence: { message: 'Your work must have an abstract.' }

  property :abstract, predicate: ::RDF::Vocab::DC.abstract do |index|
    index.as :stored_searchable
  end
end
