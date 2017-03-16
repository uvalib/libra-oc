require_dependency 'libraoc/toggles'

Toggles.config do |config|

  config[:expose_collections] = false
  config[:expose_follows] = false
  config[:expose_highlights] = false
  config[:expose_ownership_transfer] = false
  config[:expose_work_share] = false
  config[:expose_search] = true
  config[:expose_proxies] = false
  config[:expose_notifications] = false
end
#
##
## do we expose the idea of collections of works?
## the default is true
#Toggles.config.expose_collections = false
#
##
## do we expose the idea of users following other users?
## the default is true
#Toggles.config.expose_follows = false
#
##
## do we expose the idea of highlighted works?
## the default is true
#Toggles.config.expose_highlights = false
#
##
## do we expose the idea of ownership transfer?
## the default is true
#Toggles.config.expose_ownership_transfer = false
#
##
## do we expose the idea of work shares?
## the default is true
#Toggles.config.expose_work_share = false
#
##
## do we expose the search capability?
## the default is true
#Toggles.config.expose_search = true
#
##
## do we expose the idea of proxies?
## the default is true
#Toggles.config.expose_proxies = false
