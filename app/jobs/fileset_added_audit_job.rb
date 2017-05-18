class FilesetAddedAuditJob < ActiveJob::Base

  def perform( fileset, user )

    user_id = user.computing_id
    user_id = 'none' if user_id.blank?

    # TODO: find actual file name
    Audit.audit( fileset.in_works.first.id, user_id, 'files', '', fileset.id )

  end

end
