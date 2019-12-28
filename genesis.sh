#! /bin/bash

# genesis is like the tw2002 bigbang command. It creates the "material universe"
# from scratch. All sectors, planets
echo "In the beginning..."
rake genesis:create_earth \
&& rake genesis:spawn_unit
