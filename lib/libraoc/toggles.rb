module Toggles

  def self.config( &block )
    @config ||= Hash.new(defaults).with_indifferent_access
    yield @config if block
    @config
  end

  def self.defaults
    {
      expose_collections: true,
      expose_follows: true,
      expose_highlights: true,
      expose_ownership_transfer: true,
      expose_work_share: true,
      expose_search: true,
      expose_proxies: true,
      expose_notifications: true,
      expose_batch_ingest: true,
      expose_embargo_visibility: true,
      expose_lease_visibility: true
    }
  end

  private
  # Forwards any missing method call to the config hash
  # This allows us to use the method name as a convenience
  def self.method_missing(method, *args, &block)
    if @config && @config.has_key?(method)
      @config[method]
    else
      super
    end
  end
end
