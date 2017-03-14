module Toggles

  def self.config( &block )
    @config ||= Toggles::Configuration.new
    yield @config if block
    @config
  end

  class Configuration

    attr_writer :expose_collections
    def expose_collections
      @expose_collections ||= true
    end

    attr_writer :expose_follows
    def expose_follows
      @expose_follows ||= true
    end

    attr_writer :expose_highlights
    def expose_highlights
      @expose_highlights ||= true
    end

    attr_writer :expose_ownership_transfer
    def expose_ownership_transfer
      @expose_ownership_transfer ||= true
    end

  end

end
