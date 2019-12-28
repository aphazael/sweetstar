namespace :events do
  def stamp_loop(event_class, granularity: 1)
        last_tick = Events::EventTick.where(event_class: event_class).last
        now = Time.zone.now.to_f
        elapsed = now - (last_tick ? last_tick.created_at.to_f : 0.0)
        sleep(granularity - elapsed) if elapsed < granularity

        Events::EventTick.create!(event_class: event_class, instance_id: 0)
        #Lager.debug("#{event_class} tick")
        #puts("#{event_class} tick")
  end


  desc "Process troop events"
  task troop_handler: :environment do
    Lager.info("Troop Handler Started")
    while true
      begin
        time_now = Time.zone.now
        # Find all events that should have started
        active_events = Events::TroopEvent.where("start < '#{time_now}' 
          AND completed IS NULL")

        puts("#{active_events.count} active events")
        # For any that are not yet initiated, begin them, if they have yet to
        # be cancelled:
        unstarted_events = active_events.where(initiated: false)
        unstarted_events.each do |event|
          if event.cancelled
            Lager.debug("Event #{event.id} (#{event.command}) did not occur (had been cancelled before initiated)")
            event.completed = false
            event.save!
            next
          end
          # Now perform the initiate action:
          troop = Troop.find(event.troop_id)
          success = troop.method("start_#{event.command}_event").call(event.args)
          # and mark it started:
          event.initiated = true
          event.save!
        end      

        completed_events = active_events.where("finish < '#{time_now}'") # TODO TODO (not sure what I was referring to here)
        # Complete the completed ones: 
        completed_events.each do |event|
          if event.cancelled
            Lager.debug("Event #{event.id} did not occur (had been cancelled)")
            event.completed = false
            event.save!
            next
          end
          troop = Troop.find(event.troop_id)
          success = troop.method("finish_#{event.command}_event").call(event.args)
          if success == nil
            Lager.error("finish_#{event.command}() event returned nil result")
          end
          event.completed = success
          event.save! if Troop.find(event.troop_id) # "if" because this troop may have just been destroyed in combat
          troop.check_orders if troop.alive?
        end

        puts("loop complete")
        stamp_loop("TroopEvent")
      rescue StandardError => e   #Maybe we shouldn't rescue this, but let it crash
        Lager.fatal("Failure in event handler!! (#{e.message})")
        raise
      end
    end
  end
end
