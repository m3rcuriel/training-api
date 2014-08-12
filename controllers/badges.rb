module Firebots
  module InternalAPI::Controllers

    class Badges < Kenji::Controller

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badge_relations = Models::UserBadges.where(user_id: user[:id]).to_a

        yes = badge_relations.select do |relation|
          relation[:status] == 'yes'
        end.each do |relation|
          relation[:badge_id]
        end

        review = badge_relations.select do |relation|
          relation[:status] == 'review'
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
          yes: yes.map {|b| sanitized_badge(b) },
          review: review.map {|b| sanitized_badge(b) },
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

      pass '/user', UserBadges

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
