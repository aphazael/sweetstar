namespace :genesis do

  desc "Create the earth and the heavens"
  task create_earth: :environment do

    earth_size = ENV["EARTH_SIZE"] || 4

    Planet.destroy_all
    earth = Planet.create! name: "Earth", bodytype: Types::Bodytype::Q, size: earth_size.to_i
    moon = Planet.create! name: "Moon", bodytype: Types::Bodytype::D, size: 1

    Lager.global("...the Earth (and moon) was (were) created")
  end

  task spawn_unit: :environment do
    if MapGrid.first
      Lager.global("Populating the fields...")

      earth=Planet.first
      land_grids = earth&.planet_tiles&.first&.map_grids.select {|grid| grid.land?}

      num_fox = ENV["NUM_FOX"] || 3
      num_hare = ENV["NUM_HARE"] || 5

      herb_tribe = Tribe.find_by(name: "Herbivores")
      carn_tribe = Tribe.find_by(name: "Carnivores")

      num_fox.to_i.times do |n|
        Troop.create!([
          {
            unittype: Types::Unittype::FOX,
            map_grid: land_grids.sample,
            orders: [{"command" => "hunt"}],
            tribe: carn_tribe,
          },
        ])
      end

      num_hare.to_i.times do |n|
        Troop.create!([
          {
            unittype: Types::Unittype::HARE,
            map_grid: land_grids.sample, 
            orders: [{"command" => "breed"}],
            tribe: herb_tribe,
          }
        ])
      end

      Troop.all.each{|tt| tt.check_orders}

      # unit.set_move_event(MapGrid.second)
      Lager.global("...go forth and multiply")
    else
      Lager.global("no where to live!")
    end
  end

end
