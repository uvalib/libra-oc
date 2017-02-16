module CurationConcerns
  module Actors
    class ApplyOrderActor < AbstractActor
      def update(attributes)
        ordered_member_ids = attributes.delete(:ordered_member_ids)
        sync_members(ordered_member_ids)
        apply_order(ordered_member_ids) && next_actor.update(attributes)
      end

      private

        def sync_members(ordered_member_ids)
          return true if ordered_member_ids.nil?
          existing_members_ids = curation_concern.ordered_member_ids
          (existing_members_ids - ordered_member_ids).each do |old_id|
            work = ::ActiveFedora::Base.find(old_id)
            curation_concern.ordered_members.delete(work)
            curation_concern.members.delete(work)
          end

          (ordered_member_ids - existing_members_ids).each do |work_id|
            work = ::ActiveFedora::Base.find(work_id)
            curation_concern.ordered_members << work
          end
          curation_concern.save
          true
        end

        def apply_order(new_order)
          return true unless new_order
          curation_concern.ordered_member_proxies.each_with_index do |proxy, index|
            unless new_order[index]
              proxy.prev.next = curation_concern.ordered_member_proxies.last.next
              break
            end
            proxy.proxy_for = ActiveFedora::Base.id_to_uri(new_order[index])
            proxy.target = nil
          end
          curation_concern.list_source.order_will_change!
          true
        end
    end
  end
end
