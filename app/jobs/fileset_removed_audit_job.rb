class FilesetRemovedAuditJob < ActiveJob::Base

  def perform( fs_id, user )

    user_id = user.computing_id
    user_id = 'none' if user_id.blank?

    # TODO: find the work association and actual file name
    Audit.audit( 'unknown', user_id, 'files', fs_id, '' )
  end

end
