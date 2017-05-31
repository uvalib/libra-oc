class FileAddedAuditJob < ActiveJob::Base

  queue_as :audit

  # some special cases
  ID_FIELD_NAME ||= 'id'
  VISIBILITY_FIELD_NAME ||= 'visibility'

  def perform( user, before, after, file_ids )

    user_id = user.computing_id unless user.nil?
    user_id = 'none' if user_id.blank?
    audit_changes( user_id, before, after, file_ids )
  end

  private

  def audit_changes( user_id, before, after, file_ids )

    # convert to hash
    begin
      before = JSON.parse( before )
      after = JSON.parse( after )
    rescue JSON::ParserError => ex
      puts "ERROR #{ex}, no file add audit"
      return
    end

    # do not audit if this work was and continues to be private
    return if
        before[ VISIBILITY_FIELD_NAME ] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE &&
        after[ VISIBILITY_FIELD_NAME ] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    work_id = after[ ID_FIELD_NAME ]

    file_ids.each do |id|
      begin
        upload = Sufia::UploadedFile.find( id )
        Audit.audit( work_id, user_id, 'files', '', File.basename( upload.file.file.file ) )
      rescue => ex
        puts "ERROR #{ex}, no file add audit"
      end

    end

  end

end
