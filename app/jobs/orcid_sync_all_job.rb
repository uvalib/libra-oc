class OrcidSyncAllJob < ApplicationJob

  queue_as :orcid

  #
  # Syncs all LibraWorks for a newly linked ORCID User
  #
  def perform(user_id)

    user = User.find(user_id)
    if user.orcid.present?
      LibraWork.where(depositor: user.email).each do |work|

        # Sync non-complete Works
        if work.orcid_status != LibraWork.complete_orcid_status
          OrcidSyncJob.perform_later(work.id, user.computing_id)
        end
      end
    end
  end

end
