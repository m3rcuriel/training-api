require 'aws-sdk'
require 'fortune_gem'
require 'lib/email'
require 'lib/cache'

module Firebots
  module InternalAPI::Controllers

    class Badges < Kenji::Controller

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
          validates_type_of 'name', 'description', 'category', 'subcategory',
            'learning_method', 'resources', is: String
          validates_type_of 'assessment', 'verifiers', is: String, when: :is_set
          validates_type_of 'level', is: Integer, when: :is_set
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

        send_new_badge_email(badge, user)

        {
          status: 200,
          badge: sanitized_badge(badge)
        }
      end

      # Returns a list of all badges
      #
      get '/all' do
        unless badges = Cache.get('all-badges')
          Cache.set('all-badges',
            result = Models::Badges.order(:category, :level, :subcategory).all,
            60)
        end

        badges ||= result

        {
          status: 200,
          all: badges.map {|b| sanitized_badge(b) },
        }
      end

      # Updates badge properties.
      #
      patch '/:id' do |id|
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You don't have badge update permissions.")
        end

        input = kenji.validated_input do
          validates_type_of 'name', 'description', 'category', 'subcategory',
            'learning_method', 'assessment', 'resources', 'verifiers',
            is: String, when: :is_set
          validates_type_of 'level', is: Integer, when: :is_set
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

      get '/s3-creds' do
        user = requires_authentication!
        unless user[:permissions] == 'mentor' || user[:permissions] == 'lead'
          kenji.respond(403, "You don't have permissions to get S3 creds.")
        end

        s3 = AWS::S3.new
        bucket = s3.buckets['3501-training-2014-us-west-2']
        post = AWS::S3::PresignedPost.new(bucket)

        post.fields
      end

      get '/categories' do
        {
          status: 200,
          categories: get_categories.sort,
        }
      end

      get '/level/:username/:category' do |category|
        user = requires_authentication!
        user = Models::Users[username: username]

        level_hash = get_category_levels(user, category)

        {
          status: 200,
          levels: get_level(level_hash),
        }
      end

      get '/level/:category' do |category|
        user = requires_authentication!

        level_hash = get_category_levels(user, category)

        {
          status: 200,
          level: get_level(level_hash),
        }
      end

      get '/levels' do
        user = requires_authentication!

        all_levels = get_all_levels(user)

        all_levels = get_categories.map do |category|
          Hash[category, get_level(all_levels[category])]
        end.reduce({}, :merge)

        {
          status: 200,
          levels: all_levels,
        }
      end

      get '/levels/:username' do |username|
        user = requires_authentication!
        user = Models::Users[username: username]

        all_levels = get_all_levels(user)

        all_levels = get_categories.map do |category|
          Hash[category, get_level(all_levels[category])]
        end.reduce({}, :merge)

        {
          status: 200,
          levels: all_levels,
        }
      end

      delete '/:id' do |id|
        user = requires_authentication!
        unless user[:permissions] == 'mentor'
          kenji.respond(403, 'You are not allowed to delete badges.')
        end

        Models::UserBadges.where(badge_id: id).delete
        Models::Badges.where(id: id).delete

        {
          status: 200,
          message: 'Badge deleted.'
        }
      end

      pass '/user', UserBadges

      # -- Helper methods
      private

      def get_categories
        cached = Cache.get('categories')
        return cached if cached

        categories = Models::Badges.select_map(:category)
        categories = Set.new(categories).to_a

        Cache.set('categories', categories, 30)
        categories
      end

      def get_level(levels_hash)
        (1..4).each do |level|
          level_hash = levels_hash[level]

          unless level_hash[:total] != 0 && level_hash[:earned] == level_hash[:total]
            return level - 1
          end
        end

        4
      end

      def get_all_levels(user)
        get_categories.map do |category|
          counts = (1..4).map do |level|
            count_earned_badges(user, category, level)
          end.reduce({}, :merge)

          Hash[category, counts]
        end.reduce({}, :merge)
      end

      def get_category_levels(user, category)
        (1..4).map do |level|
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

      def sanitized_badge(badge)
        Hash[badge.select do |k,_|
          [:id, :time_created, :time_updated, :name, :description,
            :learning_method, :assessment, :category, :subcategory, :level,
            :resources, :verifiers].include?(k)
        end.map(&Helpers::HashPairSanitizer)]
      end

      def send_new_badge_email(badge, user)
        Firebots::Email.send(
          from: 'admin@mg.fremontrobotics.com',
          to: 'Sohini Stone <sohiniss@gmail.com>',
          cc: ['Sitar Harel <sitar@sitarharel.com>', 'Logan Howard <logan@oflogan.com>'],
          subject: 'New badge – 3501',
          text: <<-EOM
            Hi Sohini,

            #{user[:first_name]} (#{user[:title]}) has created a new #{badge[:category]} badge.
            Link: https://app.fremontrobotics.com/badge/#{badge[:id]}

            Name: #{badge[:name]}
            Subcategory: #{badge[:subcategory]}

            Description:
            #{badge[:description]}

            -----

            #{::FortuneGem.give_fortune}
          EOM
        )
      end
    end
  end
end
