module CurationConcerns
  module Actors
    class AddToCollectionActor < AbstractActor
      def create(attributes)
        collection_ids = attributes.delete(:collection_ids)
        next_actor.create(attributes) && add_to_collections(collection_ids)
      end

      def update(attributes)
        collection_ids = attributes.delete(:collection_ids)
        add_to_collections(collection_ids) && next_actor.update(attributes)
      end

      private

        # The default behavior of active_fedora's aggregates association,
        # when assigning the id accessor (e.g. collection_ids = ['foo:1']) is to add
        # to new collections, but not remove from old collections.
        # This method ensures it's removed from the old collections.
        def add_to_collections(new_collection_ids)
          return true unless new_collection_ids
          # remove from old collections
          (curation_concern.in_collection_ids - new_collection_ids).each do |old_id|
            collection = ::Collection.find(old_id)
            # don't remove from collections current user doesn't have edit permissions for
            if collection.edit_users.include? user.email
              collection.members.delete(curation_concern)
              collection.save
            end
          end

          # add to new
          new_collection_ids.each do |coll_id|
            collection = ::Collection.find(coll_id)
            collection.members << curation_concern
            collection.save
          end
          true
        end
    end
  end
end
