module Firebots
  module InternalAPI::Controllers

    class Badges < Kenji::Controller

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badge_relations = Models::UserBadges.where(user_id: user[:id]).to_a

        earned = badge_relations.select do |relation|
          relation[:status] == 'earned'
        end.each do |relation|
          relation[:badge_id]
        end

        earning = badge_relations.select do |relation|
          relation[:status] == 'earning'
        end.each do |relation|
          relation[:badge_id]
        end

        no = badge_relations.select do |relation|
          relation[:status] == 'no'
        end.each do |relation|
          relation[:badge_id]
        end

        {
          status: 200,
          earned: earned.map {|b| sanitized_badge(b) },
          earning: earning.map {|b| sanitized_badge(b) },
          no: no.map {|b| sanitized_badge(b) },
        }
      end

      # Returns a specified badge.
      #
      get '/:id' do |id|
        badge = Models::Badges[id: id.to_i]
        kenji.respond(404, 'No such badge.') unless badge

        {
          status: 200,
          badge: sanitized_badge(badge),
        }
      end

      # Creates a new badge
      #
      post '/' do
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You don't have badge creation permissions.")
        end

        input = kenji.validated_input do
          validates_type_of 'name', 'description',
            'learning_method', 'assessment', is: String
        end

        input[:id] = Rubyflake.generate

        Models::Badges.insert(input.merge(
          time_created: Time.now,
          time_updated: Time.now,
        ))

        badge = Models::Badges[id: input[:id]]

        all_users = Models::Users.all
        all_users.each do |user|
          Models::UserBadges.insert({
            user_id: user[:id],
            badge_id: badge[:id],
            status: 'no',
            id: Rubyflake.generate,
            time_created: Time.now,
            time_updated: Time.now,
          })
        end

        {
          status: 200,
          badge: sanitized_badge(badge)
        }
      end

      # Returns a list of all badges
      #
      get '/all' do
        badges = Models::Badges.all

        {
          status: 200,
          all: badges.map {|b| sanitized_badge(b) },
        }
      end

      # Updates badge properties.
      #
      route :patch, '/:id' do |id|
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You don't have badge update permissions.")
        end

        input = kenji.validated_input do
          validates_type_of 'name', 'description',
            'learning_method', 'assessment', is: String, when: :is_set
        end

        badge = Models::Badges[id: id.to_i]
        kenji.respond(404, 'No such badge.') unless badge

        Models::Badges.where(id: badge[:id]).update(input.merge(
          time_updated: Time.now,
        ))

        {
          status: 200,
          message: 'Badge info changed.',
        }
      end

      route :patch, '/user' do
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

      get '/user/:id' do |id|
        badge_relations = Models::UserBadges.where(user_id: user[:id]).to_a

        earned = badge_relations.select do |relation|
          relation[:status] == 'earned'
        end.each do |relation|
          relation[:badge_id]
        end

        earning = badge_relations.select do |relation|
          relation[:status] == 'earning'
        end.each do |relation|
          relation[:badge_id]
        end

        no = badge_relations.select do |relation|
          relation[:status] == 'no'
        end.each do |relation|
          relation[:badge_id]
        end

        {
          status: 200,
          earned: earned.map {|b| sanitized_badge(b) },
          earning: earning.map {|b| sanitized_badge(b) },
          no: no.map {|b| sanitized_badge(b) },
        }
      end

      # -- Helper methods
      private

      def sanitized_badge(badge)
        Hash[badge.select do |k,_|
          [:id, :time_created, :time_updated, :name, :description, :learning_method, :assessment].include?(k)
        end.map(&Helpers::HashPairSanitizer)]
      end
    end
  end
end
