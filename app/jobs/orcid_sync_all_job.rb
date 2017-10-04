class OrcidSyncAllJob < ApplicationJob

  #
  # Syncs all LibraWorks for a newly linked ORCID User
  #
  def perform(user_id)

    user = User.find(user_id)
    LibraWork.where(depositor: user.email).each do |work|
      OrcidSyncJob.perform_later(work.id, user.computing_id)
    end
  end

end
