require_dependency 'libraoc/serviceclient/orcid_access_client'

class ApplicationJob < ActiveJob::Base
  include ::OrcidHelper

end
