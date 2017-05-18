#
# Add a job for the fileset added event
#
CurationConcerns.config.callback.set(:after_create_fileset) do |file_set, user|
  fileset_added( file_set, user )
end

#
# Add a job for the fileset deleted event
#
CurationConcerns.config.callback.set(:after_destroy) do |fs_id, user|
  fileset_removed( fs_id, user )
end

#
# we want to continue to call the existing curation concerns jobs
#
def fileset_added( file_set, user )
  FileSetAttachedEventJob.perform_later( file_set, user)
  FilesetAddedAuditJob.perform_later( file_set, user )
end

def fileset_removed( fs_id, user )
  ContentDeleteEventJob.perform_later( fs_id, user)
  FilesetRemovedAuditJob.perform_later( fs_id, user )
end
