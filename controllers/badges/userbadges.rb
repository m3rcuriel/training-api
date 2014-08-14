module Firebots
  module InternalAPI::Controllers

    class UserBadges < Kenji::Controller

      route :patch, '/' do
        user = requires_authentication!
        unless user[:permissions] == 'mentor'
          kenji.respond(403, "You are not allowed to change user badges.")
        end

        input = kenji.validated_input do
          validates_array 'delta' do
            validates_child_hash 'self' do
              validates_type_of 'status', is: String
              validates_type_of 'id', is: Bignum
            end
          end
        end

        input[:delta].each do |badge|
          Models::UserBadges.where(id: badge[:id]).update(badge.merge(
            time_updated: Time.now,
            reviewer_id: user[:id]
          ))
        end

        {
          status: 200,
          message: 'User badge data updated.',
        }
      end

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badge_relations = Models::UserBadges.where(user_id: user[:id]).to_a

        yes = badge_relations.select do |relation|
          relation[:status] == 'yes'
        end

        review = badge_relations.select do |relation|
          relation[:status] == 'review'
        end

        no = badge_relations.select do |relation|
          relation[:status] == 'no'
        end

        {
          status: 200,
          yes: yes.map {|r| sanitized_badge_relation(r) },
          review: review.map {|r| sanitized_badge_relation(r) },
          no: no.map {|r| sanitized_badge_relation(r) },
        }
      end

      get '/:id' do |id|
        badge_relations = Models::UserBadges.where(user_id: id).to_a

        earned = badge_relations.select do |relation|
          relation[:status] == 'earned'
        end.map do |relation|
          relation[:badge_id]
        end

        earning = badge_relations.select do |relation|
          relation[:status] == 'earning'
        end.map do |relation|
          relation[:badge_id]
        end

        no = badge_relations.select do |relation|
          relation[:status] == 'no'
        end.map do |relation|
          relation[:badge_id]
        end

        {
          status: 200,
          earned: earned,
          earning: earning,
          no: no,
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
