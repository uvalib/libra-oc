class FilesetRemovedAuditJob < ActiveJob::Base

  def perform( fileset, user )

    user_id = user.computing_id
    user_id = 'none' if user_id.blank?
    Audit.audit( fileset.in_works.first.id, user_id, 'files', fileset.label, '' )
  end

end
