require_dependency 'libraoc/serviceclient/orcid_access_client'

module Libraoc::OrcidBehavior

    extend ActiveSupport::Concern

    # ORCID_STATUSES
    ORCID_STATUSES = {pending: "Pending",
                      incomplete: "Incomplete",
                      complete: "Complete"}.freeze

    private

end
