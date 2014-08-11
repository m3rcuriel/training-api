module Firebots
  module InternalAPI::Controllers

    class Badges < Kenji::Controller

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badges = Models::Badges.where(user_id: user[:id]).to_a

        {
          status: 200,
          badges: badges.map {|b| sanitized_badge(b) },
        }
      end

      # Returns a specified badge.
      #
      get '/:id' do |id|
        user = requires_authentication!

        badge = Models::Badges[id: id.to_i]
        kenji.respond(404, 'No such badge.') unless badge && badge[:user_id] == user[:id]

        {
          status: 200,
          badge: sanitized_badge(badge),
        }
      end

      # Returns a list of all badges
      #
      get '/list' do
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

        input = kenji.validated_input do
          validates_type_of 'name', is: String
          validates_type_of 'description', is: String
        end

        badge = Models::Badges[id: id.to_i]
        kenji.respond(404, 'No such badge.') unless badge

        Models::Badges.where(id: badge[:id]).update(input.merge(
          time_updated: Time.now
        ))

        {
          status: 200,
          message: 'Badge settings changed.',
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
