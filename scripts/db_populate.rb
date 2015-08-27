require File.expand_path('../../init', __FILE__)
require 'lib/password'
require 'lib/database'

class Integer
  def day; self * 86400; end
  def hr; self * 3600; end
  def min; self * 60; end
end

DB.transaction do
  test_user = {
    id: Rubyflake.generate,
    first_name: 'Test',
    last_name: 'User',
    time_created: Time.now - (101.day + 3.hr + 2.min + 5),
    time_updated: Time.now - (30.day + 0.hr + 4.min + 27),
    email: 'demo@example.com',
    permissions: 'student',
    username: 'test',
    title: 'important title',
    technical_group: 'mechanical',
    nontechnical_group: 'pr',
    bio: 'I am the swaggiest test user, man!!!',
  }
  Models::Users.insert(test_user)
  Firebots::Password.new(test_user).save_password!('to the moon')

  badge_1 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 4.min + 1,
    time_updated: test_user[:time_created] + 4.min + 1,
    name: 'Mello',
    description: 'Can make basic changes to controllers. Able to submit pull requests for this, and respond to reviews in a timely manner. Has obtained Software Environments 3.',
    learning_method: 'Logan will be available for questions, will assign tasks of increasing difficulty to those interested, and will review code.',
    assessment: 'Performance task & mentor interview',
    category: 'Software',
    subcategory: 'Kenji',
    year: 2015,
  }
  Models::Badges.insert(badge_1)

  badge_2 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 48.min + 15,
    time_updated: test_user[:time_created] + 48.min + 15,
    name: 'Near',
    description: 'Can make complex changes to controllers and basic changes to libraries. Able to read DB migrations.',
    learning_method: 'Logan will be available for questions, will assign tasks of increasing difficulty to those interested, and will review code.',
    assessment: 'Performance task & mentor interview',
    category: 'Software',
    subcategory: 'Kenji',
    year: 2015,
  }
  Models::Badges.insert(badge_2)

  badge_3 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 1.hr + 4.min + 1,
    time_updated: test_user[:time_created] + 1.hr + 38.min + 26,
    name: 'Light',
    description: 'Can make complex changes to controllers and libraries. Able to create DB migrations. Able to use various command line tools to test and debug.',
    learning_method: 'Logan will be available for questions, will assign tasks of increasing difficulty to those interested, and will review code.',
    assessment: 'Performance task & mentor interview?',
    category: 'Software',
    subcategory: 'Kenji',
    year: 2015,
  }
  Models::Badges.insert(badge_3)

  badge_4 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 6.hr + 1.min + 23,
    time_updated: test_user[:time_created] + 6.hr + 55.min + 34,
    name: 'L',
    description: 'Can make changes to training api in all areas. Able to submit pull requests that demonstrate competance in and knowledge of Kenji and Ruby principles. Comments on pull requests with comprehensive and constructive feedback.',
    learning_method: 'Logan will be available for questions, will assign tasks of increasing difficulty to those interested, and will review code.',
    assessment: 'Performance task & mentor interview',
    category: 'Software',
    subcategory: 'Kenji',
    year: 2015,
  }
  Models::Badges.insert(badge_4)

  user_badge_1 = {
    id: Rubyflake.generate,
    user_id: test_user[:id],
    badge_id: badge_1[:id],
    status: 'yes',
    time_created: badge_1[:time_created] + 7.hr + 2.min,
    time_updated: badge_1[:time_created] + 7.hr + 2.min,
  }
  Models::UserBadges.insert(user_badge_1)

  user_badge_2 = {
    id: Rubyflake.generate,
    user_id: test_user[:id],
    badge_id: badge_2[:id],
    status: 'yes',
    time_created: badge_1[:time_created] + 7.hr + 2.min,
    time_updated: badge_1[:time_created] + 7.hr + 2.min,
  }
  Models::UserBadges.insert(user_badge_2)

  user_badge_3 = {
    id: Rubyflake.generate,
    user_id: test_user[:id],
    badge_id: badge_3[:id],
    status: 'review',
    time_created: badge_1[:time_created] + 7.hr + 2.min,
    time_updated: badge_1[:time_created] + 7.hr + 2.min,
  }
  Models::UserBadges.insert(user_badge_3)

  user_badge_4 = {
    id: Rubyflake.generate,
    user_id: test_user[:id],
    badge_id: badge_4[:id],
    status: 'no',
    time_created: badge_1[:time_created] + 7.hr + 2.min,
    time_updated: badge_1[:time_created] + 7.hr + 2.min,
  }
  Models::UserBadges.insert(user_badge_4)
end
