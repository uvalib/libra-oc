class OrcidLinkJob < ApplicationJob

  #
  # Registers a user with the OrcidService
  #
  def perform(user_id)
    user = User.find(user_id)

    # Send ORCID info
    #
    # OrcidAccessClient.instance.

    OrcidSyncAllJob.perform_async(user_id)

  end
end
