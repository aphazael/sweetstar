class Troop < TypedObject
    type_class :unittype
    ## Defining characteristics. These probably never change during lifetime
    # t.string   "baseclass"    # this can be a subclass of Troop that has special behavior
    # t.string   "unit_type"    # conveyance or manner, eg "foot", "wheeled", "hover"

    ## "Permanent" attributes. These can probably be changed, but not without an operation
    # t.integer  "civ_lvl"
    # t.integer  "max_hp"
    # t.integer  "spd"         # "movement speed"
    # t.integer  "dmg"         # amount of damage done on an attack
    # t.integer  "stl"         # stealth
    # t.integer  "vis"         # vision

    ## Tracked values. These are the things that events will mostly affect
    # t.integer  "hp"
    # t.ref?     "map_grid_id" # the map_grid we are currently in
    # t.bool     "alive"

    belongs_to :tribe
    belongs_to :map_grid

    has_many :troop_event

    belongs_to_active_hash "gait", class_name: "Const::Gait"

    BASE_MOVE_RATE = 20 # seconds, but later
    COMBAT_DURATION = 10.seconds
    MATING_TIME = 20.seconds

    def destroy_self
        self.alive = false
        Lager.info("Troop #{id} is destroyed")
    end

    def all_events_for
        # Find both events we're the primary for
        events = Events::TroopEvent.where(troop: self).to_a
        # And ones we're the target of:
        events + Events::TroopEvent.where("args->'target' = ?", id.to_s).to_a
        # why do we have to cast to a string, postgres?
    end

    def initialize(args={})
        super(args)
        self.save! # is it really worth the double save 
        self.name = "#{unittype.sym}-#{id%125}"

        self.hp = self.max_hp
        # This is probably over-specific to work into the type/const system:
        self.gait = Const::Gait.find_by(shortname: self.unittype.gait)
        self.movement_factor_roughness = self.gait.roughness_penalty
        self.movement_factor_density = self.gait.density_penalty
        self.movement_factor_softness = self.gait.softness_penalty
    end

    def time_to_move(start_grid, end_grid)
        return unless end_grid.in? start_grid.map_grids 
        return unless end_grid.land?

        base_time = (BASE_MOVE_RATE - spd)

        # TODO: Maybe movement time should be based on terrain
        # in current grid, not other one?
        grade_diff = zero_or(end_grid.grade - start_grid.grade)
        roughness = end_grid.roughness
        softness = end_grid.softness
        density = end_grid.density

        roughness_mod = roughness * movement_factor_roughness
        softness_mod = softness * movement_factor_softness
        density_mod = density * movement_factor_density

        total_mod = 1 + roughness_mod + softness_mod + density_mod + grade_diff

        (base_time * total_mod).seconds
    end

    def to_h
        unit_hash = self.attributes.except("created_at", "updated_at")

        # find next event to happen
        event_at = Events::TroopEvent.where(troop:self).where("completed is null").map{|ev| ev.finish}.min.to_i
        unit_hash["next_event_in"] = event_at - Time.now.to_i
        return unit_hash
    end

    def zero_or(value)
        # TODO: this belongs in some sort of util module
        return 0 unless value
        value > 0 ? value : 0
    end

    def set_move_event(destination_location, start_time=nil)
        unless alive?
            Lager.error("set_move on dead unit #{id}")
            return
        end
        start_time = Time.zone.now unless start_time
        start_location = map_grid
        destination_location = MapGrid.find_by(id: destination_location) if destination_location.is_a? Numeric
        fail "SetEventError" unless destination_location
        fail "SetEventError: non-adjacent" unless destination_location.in? start_location.map_grids
        duration = time_to_move(start_location, destination_location)

        #puts "#{duration} seconds to move!"

        Events::TroopEvent.create!({
            command: :move,
            troop_id: id,
            start: start_time,
            finish: start_time + duration,
            args: {
                destination: destination_location.id,
            },
        })
    rescue
        Lager.fatal("SetEventError: troop #{id} cant move to grid #{destination_location.id}")
    end

    def start_move_event(args)
        return unless alive?
        self.moving = true
        self.save!
    end

    # All handle_* methods should return a [success?, message] pair
    def finish_move_event(args)
        return false unless alive?
        # converting to/from json de-symbolizes keys. Maybe we should convert
        # args in the event worker
        current_location = map_grid
        destination = MapGrid.find_by(id: args["destination"])
        unless destination
            Lager.debug("Bad Destination for troop #{id}")
            self.moving = false
            self.save!
            return false
        end
        unless current_location.adjacent? destination # We should check this when the move begins too?
            Lager.info("Troop #{id} cant move to #{destination.id} from #{current_location.id}")
            self.moving = false
            self.save!
            return false
        end

        if true # if all the things are ok
            self.map_grid = destination
            self.moving = false
            self.save!
            Lager.info("Troop #{id} moves to #{destination.id}")
            other_units = destination.troops.reject{ |unit| (unit == self) || (!unit.alive?) }
            other_units.each do |other|
                # We're going to start a separate combat event with each
                # eligible unit that's here. We'll change that later when
                # we have a concept of stacks

                # What we *really* need is to break this stuff out into an
                # on_move callback, or somethng like that
                if self.tribe.attitude_toward(other.tribe) < 0
                    set_combat_event(other)
                    self.orders = [{"command" => "combat", "since" => Time.zone.now.to_f}] + self.orders
                    save!
                    other.orders = [{"command" => "combat", "since" => Time.zone.now.to_f}] + other.orders
                    other.save!
                elsif self.unittype_id == other.unittype_id 
                    # Then mate, but only if these are critters (thus the need
                    # to do this in a type-specific callback)
                    self.set_mate_event(other)
                end
            end
            return true
        end
        Lager.error("Move failed for troop #{id}")
        false
    end

    def set_combat_event(target)
        unless target and target.alive?
            Lager.error("bad combat set for #{id} and #{target ? target.id : nil}")
            return
        end
        Lager.error("set_combat on dead unit #{id}") unless alive?
        # Check for proximity first
        start_time = Time.zone.now
        duration = COMBAT_DURATION
        Events::TroopEvent.create!({
            command: :combat,
            troop_id: id,
            start: start_time,
            finish: start_time + duration,
            args: {
                target: target.id,
            },
        })
    end

    def start_combat_event(args)
        other = Troop.find(args['target'])
        unless alive? and other.alive?
            Lager.info("Can't start combat with dead units (#{id} or #{other.id})")
            return
        end
        Lager.info("Combat started between #{id} and #{args['target']}")
        self.fighting = true
        self.save!
        other.fighting = true
        other.save!
    end

    def finish_combat_event(args)
        # TODO: this needs soooo much work
        target = Troop.find(args['target'])
        Lager.info("Combat Complete! Troop id #{id} attacking troop #{target.id}")
        target.hp = target.hp - self.dmg
        Lager.debug(" - attacker does #{self.dmg} damage. Target has #{target.hp} remaining")
        self.hp = self.hp - target.dmg
        Lager.debug(" - and recives #{target.dmg} damage. #{self.hp} remain")

        self.fighting = false
        if self.alive?
            self.check_for_death
        end
        self.save!

        target.fighting = false
        if target.alive?
            target.check_for_death
        end
        target.save!
        return true
    end

    def set_mate_event(target, start_time=nil)
        starts = start_time = Time.zone.now
        Events::TroopEvent.create!({
            command: :mate,
            troop_id: id,
            args: {target: target.id},
            start: starts,
            finish: starts + MATING_TIME,
        })
    end

    def start_mate_event(args)
        other = Troop.find(args['target'])
        unless alive? and other.alive?
            Lager.info("Can't mate dead units (#{id} or #{other.id})")
            return
        end
        unless map_grid_id == other.map_grid_id
            Lager.info("Mating failed: units #{id} and #{other.id} not in same location")
            return
        end
        Lager.info("Mating started between #{id} and #{args['target']}")
        self.orders = [{"command" => "mate", "since" => Time.zone.now.to_f}] + self.orders
        save!
        other.orders = [{"command" => "mate", "since" => Time.zone.now.to_f}] + other.orders
        other.save!
    end

    def finish_mate_event(args)
        unless alive?
            Lager.info("Unit #{id} died while mating")
            return
        end
        baby = Troop.create!({
            unittype: self.unittype,
            map_grid: self.map_grid,
            orders: [self.orders.last], # That's a little weird, but it'll do for now
            tribe: self.tribe,
        })
        Lager.info("New #{baby.unittype.name} born! Welcome, #{baby.id}!")
        baby.check_orders
    end

    def set_wait_event(duration, starts=nil)
        unless alive?
            Lager.error("set_wait on dead unit #{id}")
            return
        end
        starts ||= Time.zone.now
        Events::TroopEvent.create!({
            command: :wait,
            troop_id: id,
            args: {},
            start: starts,
            finish: starts + duration,
        })
    end

    def start_wait_event(args)
        return
    end

    def finish_wait_event(args)
        return alive?
    end

    def icon_file_name
        # This is just the "icon" field from the unittype
        unittype.icon
    end

    def check_orders
        # First, see if any orders have been completed, and handle
        # the situation:
        debug_order_array = orders.map{|oo| oo["target"] ? [oo["command"], oo["target"]] : oo["command"] }
        Lager.info("Troop #{id} is checking orders: #{debug_order_array}")
        # TODO: it feels like this belongs in the event handler (part of big
        # event refactor)
        completed_logical = check_orders_for_completion
        num = completed_logical.length
        while completed_logical.first == true
            Lager.debug("Troop #{id} COMPLETED order #{orders.first}")
            # So, just pop the first element off both lists 
            completed_logical = completed_logical[1..num]
            self.orders = self.orders[1..num]
        end
        save!

        # Then, examine the first order left on the list and maybe
        # set an event
        return if self.orders.empty?
        order = self.orders.first
        command = order["command"]

        # TODO: What we will have to do is have each "unitclass" (eg critter,
        # engineer, military, hero, worker, etc) have a mapping of command
        # names to method names that those commands will call, and then this
        # switch block will just have to call out to those functions (which
        # will live in the sub-modules), passing it the args as well.

        # But for now, we've got this:

        # These two revert to move_random if there's nothing to do, so we will
        # for them first:
        if command == "hunt"
            nearby_troops = map_grid.all_troops_within(2).reject{|tt| self==tt or !tt.alive?}
            command = "move_random" # So if there's nothing to do, we still act
            if nearby_troops.present?
                #enemy_locations = nearby_troops.select{|other| self.tribe.attitude_toward(other.tribe) < 0}.map{|bogey| bogey.map_grid_id}
                enemies = nearby_troops.select{|other| self.tribe.attitude_toward(other.tribe) < 0}
                if enemies.present?
                    # TODO: we need helpers for "push an order on the list" and "pop and order off"
                    target = enemies.sample.id
                    if target
                        self.orders = [{"command" => "attack", "target" => target}] + self.orders
                        save!
                        command = "attack"
                    end
                end
            end
        elsif command == "breed"
            nearby_troops = map_grid.all_troops_within(2).reject{|tt| self==tt or !tt.alive?}
            command = "move_random" # So if there's nothing to do, we still act
            if nearby_troops.present?
                friends = nearby_troops.select{|other| self.unittype_id == other.unittype_id}
                if friends.present?
                    # TODO: we need helpers for "push an order on the list" and "pop and order off"
                    target = friends.sample
                    if target
                        self.orders = [{"command" => "move_to", "target" => target.map_grid_id}] + self.orders
                        save!
                        command = "move_to"
                    end
                end
            end
        end

        # Since an order could have been added above, reset these locals:
        order = self.orders.first
        command = order["command"]

        if command == "move_random"
            choices = self.map_grid.map_grids.select{ |grid| grid.land? }.map{ |grid| grid.id }
            unless choices.empty?
                set_move_event(choices.sample)
            else
                Lager.error("Troop #{id} has no where to move. Fuck")
                set_wait_event(10)
            end
        elsif command == "move_to"
            target = order["target"].to_i
            first_move = shortest_path_to(target)
            if first_move
                set_move_event(first_move)
            else
                Lager.warn("Troop #{id} cant reach its destination #{target}")
                set_wait_event(10)
            end
        elsif command == "attack"
            target = self.orders.first["target"] # don't use local var order, because this order may have just been set
            if target
                first_step = shortest_path_to(Troop.find(target).map_grid_id)
                # TODO: if target is out-of-range, fail order?
                if first_step
                    set_move_event(first_step)
                else
                    Lager.error("Troop#{id} trying to attack target it cannot reach")
                end
            else
                Lager.error("Troop #{id} attacking nil target. Why?")
                set_wait_event(10)
            end
        elsif command == "combat"
            # need to set "wait" event or something, so that this gets checked again
            set_wait_event(COMBAT_DURATION)
        elsif command == "mate"
            set_wait_event(MATING_TIME)
        end
    rescue StandardError => e
        byebug
    end

    def check_orders_for_completion
        # the troop orders attribute is a list, so we will return
        # a list of booleans, indicating if any is complete
        orders.map do |order|
            c = false
            # What's a case statement?
            if order["command"] == "move_random"
                c = false
            elsif order["command"] == "move_to"
                c = order["target"].to_i == map_grid.id
            elsif order["command"] == "combat"
                c = (!self.fighting?) && (Time.zone.now.to_f > (order['since'].to_f + COMBAT_DURATION))
            elsif order["command"] == "mate"
                c = Time.zone.now.to_f > (order['since'].to_f + MATING_TIME)
            elsif order["command"] == "attack"
                c = !Troop.find(order["target"].to_i).alive?
            end
            c #wtf
        end
    end

    def check_for_death
        if self.hp <= 0
            Lager.info("Troop #{id} id dead!")
            self.destroy_self
        end
    end

    def quick_stats
        "#{name} (#{hp}/#{max_hp} hp)"
    end

    def shortest_path_to(end_grid_id)
        # We want to know just what the first move on the path is,
        # and return the id thereof
        start_grid = self.map_grid
        end_grid = MapGrid.find(end_grid_id)
        return end_grid_id if start_grid==end_grid

        # Dijkstra's algorithm, sort of
        explored = Containers::PriorityQueue.new
        completed = [start_grid]
        first_moves = {}
        start_grid.map_grids.each do |grid|
            time = time_to_move(start_grid, grid)
            next unless time
            explored.push([grid, time], -time) # negative because the PQueue is greatest first
            first_moves[grid] = [grid, time]
        end

        until explored.empty?
            exploring, distance = explored.pop()
            if exploring==end_grid
                # If we just pulled off the node we're looking for, we found the shortest path
                return first_moves[exploring][0].id
            end
            next if exploring.in? completed
            completed << exploring
            # Otherwise, explore the grids accessible from here:
            exploring.map_grids.each do |grid|
                this_leg = self.time_to_move(exploring, grid)
                next unless this_leg # If it's a water tile, then the t_t_m will be nil
                new_distance = this_leg + distance
                if !first_moves[grid] || first_moves[grid][1] > new_distance
                    # If either we havent gotten here yet or this time/distance
                    # is shorter than the one we already have, then replace it
                    first_moves[grid] = [first_moves[exploring][0], new_distance]
                end
                # I feel like we need to have this here in case theres another
                # path around, but it also seems to lead to an infinite loop.
                # Do we need a done list?
                explored.push([grid, new_distance], -new_distance)
            end
        end
    end

end
  # t.integer  "troop_id"
  # t.string   "command",    null: false
  # t.string   "args",       null: false
  # t.datetime "start",      null: false
  # t.datetime "finish",     null: false
  # t.boolean  "completed"
  # t.boolean  "cancelled"
  # t.datetime "created_at", null: false
  # t.datetime "updated_at", null: false

