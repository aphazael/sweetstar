#! /bin/bash

# bigbang is the equivalent of rake db:drop db:create db:migrate. It completely
# resets the state of the whole project as though it were being installed on a
# brand new machine. 
echo "This will destroy everything. Are you sure? (y/n)"
echo "(Better [ctrl-c] P.D.Q. if not!)"
    # answer = gets
    # if answer.in? %w(n no N NO)
    #   puts "...ok"
    #   break
    # end 

rake bigbang:reset \
&& rake bigbang:seed_rules \
&& rake bigbang:system_categories

# Re-creating the database will probably wipe out all the user information too,
# so we will probably have to generate the first few "users" here (the admin
# account, as well as users/corps/guilds/whatever for the federation, etc)
# rake bigbang:superusers # or something

