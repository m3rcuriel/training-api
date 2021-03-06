require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class UserBadges < Kenji::Controller

      # Updates an arbitrary user's badge relations.
      #
      patch '/' do
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You are not allowed to change user badges.")
        end

        input = kenji.validated_input do
          validates_type_of 'status', is: String, when: :is_set
          validates_type_of 'badge_id', 'user_id', is: String
        end

        unless input['status']
          input['status'] = 'yes' if user[:permissions] == 'mentor'
          input['status'] = 'review' if user[:permissions] == 'lead'
        end

        if input['status'] == 'yes' && user[:permissions] == 'lead'
          kenji.respond(403, 'Only mentors can link badges.')
        end

        badge_id = input['badge_id']
        user_id = input['user_id']

        Models::UserBadges
          .where(badge_id: badge_id, user_id: user_id)
          .update(
            input.merge(
              time_updated: Time.now,
              reviewer_id: user[:id],
            )
          )

        if input['status'] == 'no'
          message = 'User unlinked from badge.'
        else
          message = 'User linked with badge.'
        end

        {
          status: 200,
          message: message,
        }
      end

      # Lists the user's badges.
      #
      get '/' do
        user = requires_authentication!

        badge_relations = Models::UserBadges
          .where(user_id: user[:id])
          .all

        {
          status: 200,
          badge_relations: badge_relations.map {|r| sanitized_badge_relation(r) },
        }
      end

      # Lists an arbitrary users's badges.
      #
      get '/:username' do |username|
        user_id = Models::Users[username: username][:id]
        badge_relations = Models::UserBadges
          .where(user_id: user_id)
          .all

        {
          status: 200,
          badge_relations: badge_relations.map {|r| sanitized_badge_relation(r) },
        }
      end

      # Lists how many badges from each category a user has.
      #
      get '/:username/category-count' do |username|
        {
          status: 200,
          category_counts: count_categories(username)
        }
      end

      # Lists how many badges from each category the current user has.
      #
      get '/category-count' do
        {
          status: 200,
          category_counts: count_categories(user[:username]),
        }
      end

      # Lists every badge that every user has with the given status
      #
      get '/all' do
        input = kenji.validated_input do
          validates_type_of 'status', is: String, when: :is_set
        end

        status = input['status'] || 'review'

        unless badges = Cache.get("#{status}-all-user-badges")
          Cache.set("#{status}-all-user-badges",
            result = all_user_badges(status),
            2)
        end

        badges ||= result

        {
          status: 200,
          all: badges.reject{ |k, v| v.nil? },
        }
      end

      # Lists all users that have a given badge.
      #
      get '/badge/:id' do |id|
        all_user_ids = Models::Users
          .where(archived: false)
          .select_map(:id)

        users_badges_hash = all_user_ids.map do |user_id|
          relation = Models::UserBadges[badge_id: id, user_id: user_id, status: 'yes']
          user = Models::Users[id: user_id]

          Hash[user[:username], relation]
        end.reduce({}, :merge)

        users_badges_hash
          .reject { |k, v| v.nil? }
          .each do |k, v|
            user = Models::Users[username: k]
            users_badges_hash[k].update(
              username: user[:username],
              email: user[:email],
              first_name: user[:first_name]
            )
          end

        {
          status: 200,
          relations: users_badges_hash.reject{ |k, v| v.nil? },
        }
      end


      private

      def all_user_badges(status)
        all_users = Models::Users.where(archived: false).all

        users_badges_hash = all_users.map do |user|
          badge_relations = Models::UserBadges
            .where(status: status, user_id: user[:id])

          # array of badge ids and of user ids
          badge_ids = badge_relations.select_map(:badge_id)
          reviewer_ids = badge_relations.select_map(:reviewer_id)

          # [a,b].zip([c, d]) = [[a,c],[b,d]]
          badges = badge_ids.zip(reviewer_ids).map do |badge_id, reviewer_id|
            reviewer = Models::Users[id: reviewer_id]
            if reviewer
              reviewer_data = {
                first_name: reviewer[:first_name],
                last_name: reviewer[:last_name],
              }
            else
              reviewer_data = {
                first_name: 'Unknown',
                last_name:  'Reviewer',
              }
            end

            {
              badge_id: badge_id,
              reviewer: reviewer_data,
            }
          end

          Hash[user[:username], {
            badges: badges,
            user: {first_name: user[:first_name], last_name: user[:last_name]},
          }]
        end.reduce({}, :merge)
        .delete_if {|k, v| v[:badges].empty?}
      end

      def count_categories(username)
        user = Models::Users[username: username]
        kenji.respond(404, 'No such user.') unless user
        user_id = user[:id]

        categories = Models::Badges.select_map(:category)
        categories = Set.new(categories).to_a

        categories.map do |category|
          earned_badge_relations = Models::UserBadges
            .where(user_id: user_id, status: 'yes')

          earned_badges = earned_badge_relations.map do |relation|
            Models::Badges[id: relation[:badge_id], category: category]
          end

          Hash[category, earned_badges.compact.count]
        end.reduce({}, :merge)
      end

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
