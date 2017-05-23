#
# Add a job for the fileset added event
#
CurationConcerns.config.callback.set(:after_create_fileset) do |file_set, user|
  fileset_added( file_set, user )
end

#
# we want to continue to call the existing curation concerns jobs
#
def fileset_added( file_set, user )
  FileSetAttachedEventJob.perform_later( file_set, user)
  FilesetAddedAuditJob.perform_later( file_set, user )
end