class FilesetRemovedAuditJob < ActiveJob::Base

  def perform( work_id, filename, user )

    user_id = user.computing_id
    user_id = 'none' if user_id.blank?
    Audit.audit( work_id, user_id, 'files', filename, '' )
  end

end
