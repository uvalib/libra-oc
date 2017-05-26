# Converts UploadedFiles into FileSets and attaches them to works.

#
# this is a duplicate of the version found in sufia so we can add a call to generate the audit record
# the difference is called out in the code
#

class AttachFilesToWorkJob < ActiveJob::Base
  queue_as :ingest

  # @param [ActiveFedora::Base] the work class
  # @param [Array<UploadedFile>] an array of files to attach
  def perform(work, uploaded_files)
    uploaded_files.each do |uploaded_file|
      file_set = FileSet.new
      user = User.find_by_user_key(work.depositor)
      actor = CurationConcerns::Actors::FileSetActor.new(file_set, user)
      actor.create_metadata(work, visibility: work.visibility) do |file|
        file.permissions_attributes = work.permissions.map(&:to_hash)
      end

      attach_content(actor, uploaded_file.file)
      uploaded_file.update(file_set_uri: file_set.uri)

      # this is the added call
      FilesetAddedAuditJob.perform_later( file_set, user )

    end
  end

  private

    # @param [CurationConcerns::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    def attach_content(actor, file)
      case file.file
      when CarrierWave::SanitizedFile
        actor.create_content(file.file.to_file)
      when CarrierWave::Storage::Fog::File
        import_url(actor, file)
      else
        raise ArgumentError, "Unknown type of file #{file.class}"
      end
    end

    # @param [CurationConcerns::Actors::FileSetActor] actor
    # @param [UploadedFileUploader] file
    def import_url(actor, file)
      actor.file_set.update(import_url: file.url)
      log = CurationConcerns::Operation.create!(user: actor.user,
                                                operation_type: "Attach File")
      ImportUrlJob.perform_later(actor.file_set, log)
    end
end
