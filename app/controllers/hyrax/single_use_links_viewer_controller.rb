module Hyrax
  class SingleUseLinksViewerController < ApplicationController
    include Hyrax::SingleUseLinksViewerControllerBehavior




    class Ability
      include CanCan::Ability

      attr_reader :single_use_link

      def initialize(user, single_use_link)
        @user = user || ::User.new

        @single_use_link = single_use_link

        can :read, [ActiveFedora::Base, SolrDocument] do |obj|
          single_use_link.valid? && single_use_link.itemId == obj.id && single_use_link.destroy!
        end if single_use_link
      end
    end


    protected

    def render_single_use_error(exception)
      logger.error("Rendering PAGE due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
      render 'single_use_error',layout: 'public_view', status: 404
    end

  end
end
