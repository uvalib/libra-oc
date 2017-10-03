require_dependency 'libraoc/serviceclient/orcid_access_client'
require_dependency 'libraoc/helpers/orcid_helpers'

module Libraoc::OrcidBehavior

    extend ActiveSupport::Concern

    # ORCID_STATUSES
    ORCID_STATUSES = %w(pending incomplete complete).freeze

    included do
      singleton_class.instance_eval do
        # defines methods to get status names ie: LibraWork.pending_orcid_status
        ORCID_STATUSES.each do |status|
          method_name = "#{status}_orcid_status".to_sym
          define_method method_name do
            status
          end
        end
      end
    end

    private

end
