class OrcidSyncJob < ApplicationJob

  #
  # Creates or updates a LibraWork in the OrcidService
  #
  def perform work_id, computing_id

    work = LibraWork.find(work_id)

    if Helpers.work_suitable_for_orcid_activity( computing_id, work ) == false
      puts "The work is not eligible for ORCID upload."
      return
    end

    status, update_code = ServiceClient::OrcidAccessClient.instance.
      set_activity_by_cid( computing_id, work )

    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      work.update orcid_put_code: update_code, orcid_status: LibraWork.complete_orcid_status
      puts "==> ORCID Upload OK for #{work_id}, update code [#{update_code}]"

    elsif ServiceClient::OrcidAccessClient.instance.retry?( status )
      work.update orcid_status: LibraWork.incomplete_orcid_status
      retry_job wait: 5.minutes
      puts "RETRYING: OrcidSyncJob for #{work_id}"

    else
      work.update orcid_status: LibraWork.incomplete_orcid_status
      # fail on other errors
      return
    end

  end
end
