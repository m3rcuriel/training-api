module Firebots
  module InternalAPI::Controllers

    class UserBadges < Kenji::Controller

      route :patch, '/' do
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You are not allowed to change user badges.")
        end

        input = kenji.validated_input do
          validates_type_of 'status', is: String, when: :is_set
          validates_type_of 'badge_id', 'user_id', is: String
        end

        unless input[:status]
          input[:status] = 'yes' if user[:permissions] == 'mentor'
          input[:status] = 'review' if user[:permissions] == 'lead'
        end

        badge_id = input['badge_id']
        user_id = input['user_id']

        Models::UserBadges.where(badge_id: badge_id, user_id: user_id).update(
          input.merge(
            time_updated: Time.now,
            reviewer_id: user[:id],
          )
        )

        {
          status: 200,
          message: 'User linked with badge.',
        }
      end

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badge_relations = Models::UserBadges.where(user_id: user[:id]).to_a

        {
          status: 200,
          badge_relations: badge_relations.map {|r| sanitized_badge_relation(r) },
        }
      end

      get '/:id' do |id|
        badge_relations = Models::UserBadges.where(user_id: id).to_a

        {
          status: 200,
          badge_relations: badge_relations.map {|r| sanitized_badge_relation(r) },
        }
      end

      private

      def sanitizer
        @sanitizer ||= Badges.new
      end

      def sanitized_badge(badge)
        sanitizer.send(:sanitized_badge, badge)
      end

      def sanitized_badge_relation(relation)
        Hash[relation.select do |k,_|
          [:id, :time_created, :time_updated, :user_id, :badge_id, :status, :reviewer_id].include?(k)
        end.map(&Helpers::HashPairSanitizer)]
      end

    end
  end
end
