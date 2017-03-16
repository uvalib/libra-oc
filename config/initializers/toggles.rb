require_dependency 'libraoc/toggles'

#
# do we expose the idea of collections of works?
# the default is true
Toggles.config.expose_collections = false

#
# do we expose the idea of users following other users?
# the default is true
Toggles.config.expose_follows = false

#
# do we expose the idea of highlighted works?
# the default is true
Toggles.config.expose_highlights = false

#
# do we expose the idea of ownership transfer?
# the default is true
Toggles.config.expose_ownership_transfer = false

#
# do we expose the idea of work shares?
# the default is true
Toggles.config.expose_work_share = false