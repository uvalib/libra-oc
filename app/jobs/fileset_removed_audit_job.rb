class FilesetRemovedAuditJob < ActiveJob::Base

  queue_as :audit

  def perform( fileset, user )

    user_id = user.computing_id unless user.nil?
    user_id = 'none' if user_id.blank?
    work = fileset.in_works.first
    return if work.nil?
    return if work.is_private?
    Audit.audit( work.id, user_id, 'files', fileset.label, '' )
  end

end
