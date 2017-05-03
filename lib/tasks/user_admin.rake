#
# Some helper tasks to create and delete users
#

# pull in the helpers
require_dependency 'tasks/task_helpers'
include TaskHelpers

namespace :libraoc do

namespace :user do

default_password = "password"

desc "Delete all users"
task del_all_users: :environment do |t, args|

  count = 0
  User.all.each do |user|
     count += 1
     user.destroy
  end
  puts "Deleted #{count} user(s)"

end

desc "Delete specified user; must provide email"
task del_user: :environment do |t, args|

  who = ARGV[ 1 ]
  if who.nil?
    puts "ERROR: no user specified, aborting"
    next
  end

  task who.to_sym do ; end

  user = User.find_by_email( who )
  if user
     user.destroy
     puts "Deleted #{who}"
  else
    puts "User #{who} does not exist"
  end

end

desc "Create new user; must provide name and email"
task create_user: :environment do |t, args|

  name = ARGV[ 1 ]
  email = ARGV[ 2 ]

  if name.nil?
    puts "ERROR: no name specified, aborting"
    next
  end

  task name.to_sym do ; end

  if email.nil?
    puts "ERROR: no email specified, aborting"
    next
  end

  task email.to_sym do ; end

  user = User.find_by_email( email )
  if user.nil?
     if create_user( name, email, default_password )
        puts "Created user: #{name} (#{email})"
     end
  else
    puts "Email #{email} already in use"
  end

end

desc "List all users"
task list_all_users: :environment do |t, args|

  count = 0
  User.order( :email ).each do |user|
    puts "User: #{user.display_name}"
    puts "  email:      #{user.email}"
    puts "  title:      #{user.title || 'None'}"
    puts "  department: #{user.department || 'None'}"
    puts "  ORCID:      #{user.orcid || 'None'}"
    puts "  created:    #{user.created_at}"
    puts "  admin:      #{user.admin? ? 'Yes' : 'No'}"
    count += 1
  end
  puts "#{count} user(s) listed"

end

desc "Sync all user data "
task sync_all_users: :environment do |t, args|

  User.all.each do |user|
    if sync_user( user ) == true
       puts "Updated user record for #{user.email}"
    end
  end

end

#
# create a new user record; attempt to lookup using the user info service
#
def create_user( name, email, password )

  # extract computing ID and look up...
  info = TaskHelpers.user_info_by_email( email )

  display_name = info.nil? ? name : info.display_name
  title = info.nil? ? name : info.description
  department = info.nil? ? name : info.department
  user = User.new( email: email,
                   password: password,
                   password_confirmation: password,
                   display_name: display_name,
                   title: title,
                   department: department )
  user.save!

  return true

end

#
# sync user data from the info service
#
def sync_user( user )

  # look up...
  info = TaskHelpers.user_info_by_email( user.email )
  updated = false

  if info.nil? == false

    if user.display_name != info.display_name
      user.display_name = info.display_name
      updated = true
    end

    if user.department != info.department
       user.department = info.department
       updated = true
    end

    if user.office != info.office
       user.office = info.office
       updated = true
    end

    if user.telephone != info.phone
       user.telephone = info.phone
       updated = true
    end

    if user.title != info.description
       user.title = info.description
       updated = true
    end

    if updated
       user.save!
    end
  end

  return updated
end

end   # namespace user

end   # namespace libraoc

#
# end of file
#