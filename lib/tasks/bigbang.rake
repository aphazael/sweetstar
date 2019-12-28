namespace :bigbang do


  desc "Destroy and re-create database"
  task reset: :environment do
    Lager.global("Rebooting the matrix...")
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
  end


  desc "Instantiate models for all the game rules"
  task seed_rules: :environment do
    Lager.global("Applying the laws of nature...")
    # Who knows. Maybe we will read all this from yaml files or something. In
    # any case this is where all the data models for things like building
    # definitions and the tech tree and troop classes will be loaded
  end

  desc "Create system users, tribes, etc"
  task system_categories: :environment do
    Lager.global("Creating the lambs and the lions")

    Tribe.create!([
      {
        name: "Herbivores",
        faction: "fauna",
        player: 0,
      },
      {
        name: "Carnivores",
        faction: "fauna",
        player: 0,

      },
    ])



  end
end
