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
    username: 'testy',
  }
  Models::Users.insert(test_user)
  Firebots::Password.new(test_user).save_password!('to the moon')

  badge_1 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 4.min + 1,
    time_updated: test_user[:time_created] + 4.min + 1,
    name: 'Example badge',
    description: 'The amazing badge of badgetown! Does this not look grand?',
    learning_method: 'You should learn this by doing a bunch of stuff lol',
    assessment: 'You have to jump off a cliff and die lolol',
  }
  Models::Badges.insert(badge_1)

  badge_2 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 48.min + 15,
    time_updated: test_user[:time_created] + 48.min + 15,
    name: 'Le badge',
    description: 'The French badge! Frenchies unite!',
    learning_method: 'Ya gotta get French lessons from that lass over yonder',
    assessment: 'You have to talk a French bear out of mauling you :))))',
  }
  Models::Badges.insert(badge_2)

  badge_3 = {
    id: Rubyflake.generate,
    time_created: test_user[:time_created] + 1.hr + 4.min + 1,
    time_updated: test_user[:time_created] + 1.hr + 38.min + 26,
    name: 'Badgeroo',
    description: 'You and me are together forever says badgey!',
    learning_method: 'Go to Australia and learn how to throw a boomerang from a tiger',
    assessment: 'Are you bonkers mate?',
  }
  Models::Badges.insert(badge_3)
end
