require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class Stats < Kenji::Controller

      # Returns names and their status in relation to every badge.
      #
      get '/names-badges' do
        cached = Cache.get('names-badges')
        return cached if cached

        # get the data for all students
        result = Models::Users
          .where(permissions: ['student', 'lead'])
          .map do |user|

            # get the status of all badge relations
            badges = Models::Badges.map do |badge|
              relation = Models::UserBadges[badge_id: badge[:id], user_id: user[:id]]

              {
                id: badge[:id],
                status: badge[:status],
              }
            end

            {
              name: "#{user[:first_name]} #{user[:last_name]}",
              badges: badges,
            }
        end

        ensure_cached('names-badges', result)
      end

      # Returns names and the number of badges they have per category.
      #
      get '/names-categories' do
        cached = Cache.get('names-categories')
        return cached if cached

        result = Models::Users
          .where(permissions: ['student', 'lead'])
          .map do |user|

            category_stats = get_all_levels(user).map do |category, badge_stats|
              Hash[category, badge_stats.map { |_, v| v[:earned] }.reduce(:+)]
            end.reduce(:merge)

            {
              user: "#{user[:first_name]} #{user[:last_name]}",
              badges_per_category: category_stats,
            }
        end

        ensure_cached('names-categories', result)
      end

      # Returns names and the level they are in each category.
      #
      get '/names-levels' do
        cached = Cache.get('names-levels')
        return cached if cached

        result = Models::Users
          .where(permissions: ['student', 'lead'])
          .order(:technical_group)
          .map do |user|
            user_levels = get_all_levels(user)

            user_levels = get_categories.map do |category|
              Hash[category, get_level(user_levels[category])]
            end.reduce(:merge)

            {
              user: "#{user[:first_name]} #{user[:last_name]}",
              levels: user_levels,
            }
        end

        ensure_cached('names-levels', result)
      end


      private

      def ensure_cached(key, result)
        result = {
          status: 200,
          result: result,
        }

        Cache.set(key, result, 24 * 3600)
        result
      end

      def get_categories
        cached = Cache.get('categories')
        return cached if cached

        categories = Models::Badges.select_map(:category)
        categories = Set.new(categories).to_a

        Cache.set('categories', categories, 30)
        categories
      end

      def get_level(levels_hash)
        (1..5).each do |level|
          level_hash = levels_hash[level]

          unless level_hash[:total] != 0 && level_hash[:earned] == level_hash[:total]
            return level - 1
          end
        end

        5
      end

      def get_all_levels(user)
        get_categories.map do |category|
          counts = (1..5).map do |level|
            count_earned_badges(user, category, level)
          end.reduce({}, :merge)

          Hash[category, counts]
        end.reduce({}, :merge)
      end

      def get_category_levels(user, category)
        (1..5).map do |level|
          count_earned_badges(user, category, level)
        end.reduce({}, :merge)
      end

      def count_earned_badges(user, category, level)
        badges = Models::Badges.where(category: category, level: level).all

        earned_badges = 0
        badges.each do |badge|
          earned_badges += 1 if Models::UserBadges[
            badge_id: badge[:id],
            user_id: user[:id],
            status: 'yes',
          ]
        end

        Hash[level, {
            total: badges.count,
            earned: earned_badges,
        }]
      end
    end
  end
end
