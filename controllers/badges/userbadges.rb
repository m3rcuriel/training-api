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

    end
  end
end
