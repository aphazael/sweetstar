class EarthController < ApplicationController
  def view
    #earth = Planet.first
    #quad = earth.planet_tiles.first
    body = params[:body] || "earth"
    @center_grid_id = (params[:grid_id] || 1).to_i
    direct = (params[:direct] || 0).to_i
    @radius = (params[:radius] || 2).to_i

    @refresh_on = true;

    planet = Planet.find_by(name: body.capitalize)
    unless params[:grid_id]
      @center_grid_id = planet&.planet_tiles&.first&.map_grids&.first&.id
    end

    dir = direct.to_s.to_sym

    @hh = "grid #{@center_grid_id}, dir #{dir}, rad #{@radius}"
    @log_msg = last_n_log(5)

    grid_map = PlanetTile.return_terrain_grid(@center_grid_id, dir, @radius.to_i)
    @terrain_grid = pad_map(grid_map)
    @troops = troops_for_space(@center_grid_id, @radius)
    @links_hash = gen_travel_links(@center_grid_id, direct, @radius)
  end

  def troops
    @center_grid_id = params[:grid_id].to_i
    @radius = params[:radius].to_i
    @troops = troops_for_space(@center_grid_id, @radius)
    render :json => @troops
  end

  def pad_map(map_table)
    map_table.each_with_index do |row, i|
      diff = (map_table.count - row.count + (i.odd? ? 1 : 0) )/2
      # put nils in front
      diff.times { |i| row.unshift(nil) }
    end
  end

  def gen_travel_links(grid_id, direct, radius)
    grid_id = grid_id.to_i
    direct = direct.to_i
    radius = radius.to_i
    
    grid = MapGrid.find(grid_id);
    links = {}
    grid_right = grid.grid_toward(direct)
    grid_left = grid.grid_toward(direct - 3)

    warble = grid_id.even? ? 1 : 0
    grid_up = grid.grid_toward(direct - (1+warble))
    grid_down = grid.grid_toward(direct + (2-warble))

    return {
      left: [grid_left.id, direct, radius],
      right: [grid_right.id, direct, radius],
      up: [grid_up.id, direct, radius],
      down: [grid_down.id, direct, radius],
      clock: [grid.id, (direct-1)%6, radius],
      counter: [grid.id, (direct+1)%6, radius], 
    }
  end

  def last_n_log(num)
    return [] if Rails.env == 'production' # because crash. file access thing? TODO
    logtext = `tail -n#{num} #{Lager::LOGFILE_PATH.to_s}`
    loglines = logtext.split("\n")
    loglines.map {|line| line.split("@@")[0]} # Split on @@ because we dont reall care about the timestamp here
  end

  def troops_for_space(grid_id, radius)
    troops = MapGrid.find(grid_id).all_troops_within(radius)
    {}.tap do |hh|
      troops.each do |unit|
        next unless unit.alive?
        unithash = unit.to_h
        unithash['asset_path'] = ActionController::Base.helpers.asset_path("units/#{unit.icon_file_name}.png")
        hh[unit.map_grid_id] = (hh[unit.map_grid_id] or []) << unithash
      end
    end
  end

end



