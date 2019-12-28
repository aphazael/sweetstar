class Lager
  LOGFILE_PATH = Rails.root.join('log','game.log')

  method_names_symbolized = %i(debug info warn error fatal global)
  method_names_symbolized.each do |mode|

    send :define_singleton_method, mode do |message|
      puts message
      log_message = "[#{mode.upcase}]: #{message} @@ #{Time.zone.now.to_f}\n"

      # Need to have it write the thing to some file:
      File.open(LOGFILE_PATH, "a+").tap do |logfile|
        logfile << log_message
      end.close

      # Also maybe write a database row with debug data?
    end
  end
   
end
