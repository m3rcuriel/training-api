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
  }
  Models::Users.insert(test_user)
  Firebots::Password.new(test_user).save_password!('to the moon')

  badge_1 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 4.min + 1,
    time_updated: test_user[:time_created] + 4.min + 1,
    name: 'Example badge',
    description: 'The amazing badge of badgetown! Does this not look grand?',
  }
  Models::Badges.insert(badge_1)

  badge_2 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 48.min + 15,
    time_updated: test_user[:time_created] + 48.min + 15,
    name: 'Le badge',
    description: 'The French badge! Frenchies unite!',
  }
  Models::Badges.insert(badge_2)

  badge_3 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 1.hr + 4.min + 1,
    time_updated: test_user[:time_created] + 1.hr + 38.min + 26,
    name: 'Badgeroo',
    description: 'You and me are together forever says badgey!',
  }
  Models::Badges.insert(badge_3)
end
