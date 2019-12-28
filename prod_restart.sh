#! /bin/bash

echo "Take sudo"
sudo echo "...ok"

echo "Stop nginx"
sudo service nginx stop

echo "Big Bang"
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 ./bigbang.sh && ./genesis.sh

echo "Compile Assets"
rake assets:precompile
touch tmp/restart.txt

echo "Restart nginx"
sudo service nginx restart

