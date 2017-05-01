require_dependency 'libraoc/toggles'

Toggles.config do |config|

  ## do we expose the idea of collections of works?
  ## the default is true
  config[:expose_collections] = false

  ## do we expose the idea of users following other users?
  ## the default is true
  config[:expose_follows] = false

  ## do we expose the idea of highlighted works?
  ## the default is true
  config[:expose_highlights] = false

  ## do we expose the idea of ownership transfer?
  ## the default is true
  config[:expose_ownership_transfer] = false

  ## do we expose the idea of work shares?
  ## the default is true
  config[:expose_work_share] = false

  ## do we expose the search capability?
  ## the default is true
  config[:expose_search] = true

  ## do we expose the idea of proxies?
  ## the default is true
  config[:expose_proxies] = false

  ## do we expose the idea of notifications?
  ## the default is true
  config[:expose_notifications] = false

  ## do we expose the idea of batched ingest?
  ## the default is true
  config[:expose_batch_ingest] = false

  ## do we expose the concept of embargo visibility for works
  ## the default is true
  config[:expose_embargo_visibility] = false

  ## do we expose the concept of lease visibility for works
  ## the default is true
  config[:expose_lease_visibility] = false

  ## do we show representative media and thumbnail selectors on the form?
  ## default is true
  config[:expose_thumbnail_form_select] = false

  ## do we show the file manager?
  ## default is true
  config[:expose_file_manager] = false

  # can we delete public work
  ## default is true
  config[:expose_public_delete] = false

  # do we show aggregate metrics on the profile page?
  ## default is true
  config[:expose_aggregate_metrics] = false
end
