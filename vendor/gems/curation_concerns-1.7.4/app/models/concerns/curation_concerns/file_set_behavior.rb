module CurationConcerns
  module FileSetBehavior
    extend ActiveSupport::Concern

    include CurationConcerns::BasicMetadata
    include Hydra::Works::FileSetBehavior
    include Hydra::Works::VirusCheck
    include CurationConcerns::FileSet::Characterization
    include Hydra::WithDepositor
    include CurationConcerns::Serializers
    include CurationConcerns::Noid
    include CurationConcerns::FileSet::Derivatives
    include CurationConcerns::Permissions
    include CurationConcerns::FileSet::Indexing
    include CurationConcerns::FileSet::BelongsToWorks
    include CurationConcerns::FileSet::Querying
    include CurationConcerns::HumanReadableType
    include CurationConcerns::RequiredMetadata
    include CurationConcerns::Naming
    include Hydra::AccessControls::Embargoable
    include GlobalID::Identification

    included do
      attr_accessor :file
      self.human_readable_type = 'File'
    end

    def representative_id
      to_param
    end

    def thumbnail_id
      to_param
    end
  end
end
