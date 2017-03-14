require_dependency 'libraoc/toggles'

#
# If we add code to turn on or off certain features (sufia for example), configure them
# here.
#
Toggles.config do |config|

  #
  # do we expose the idea of collections of works?
  # the default is true
  config.expose_collections = false

  #
  # do we expose the idea of users following other users?
  # the default is true
  config.expose_follows = false

  #
  # do we expose the idea of highlighted works?
  # the default is true
  config.expose_highlights = false

  #
  # do we expose the idea of ownership transfer?
  # the default is true
  config.expose_ownership_transfer = false

end