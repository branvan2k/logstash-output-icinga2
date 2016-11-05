# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::Icinga2 < LogStash::Outputs::Base
  config_name "icinga2"

# The full path to your Icinga2 command file.
  config :commandfile, :default => "/var/run/icinga2/cmd/icinga2.cmd"

# The icinga2 'host' you want to submit a passive check result to. This
# parameter accepts interpolation, e.g. you can use `@source_host` or other
# logstash internal variables.
  config :icinga2_host, :validate => :string, :default => "%{host}"

# The nagios 'service' you want to submit a passive check result to. This
# parameter accepts interpolation, e.g. you can use `@source_host` or other
# logstash internal variables.
  config :icinga2_service, :validate => :string, :default => "%{service}"

# The Icinga2 check level. Should be one of 0=OK, 1=WARNING, 2=CRITICAL,
# 3=UNKNOWN. Defaults to 2 - CRITICAL.
  config :icinga2_level, :validate => [ "0", "1", "2", "3" ], :default => "2"

# The format to use when writing events to Icinga2.
  config :message_format, :validate => :string, :default => "%{message}"

  public
  def register
  end # def register

  def receive(event)
        if !command_file_exist?
      @logger.warn("Skipping icinga2 output; command file is missing",
                   :commandfile => @commandfile, :missed_event => event)
      return
    end


  public
  def receive(event)
    return "Event received"
  end # def event



    host = event.get("icinga2_host")
    if !host
      @logger.warn("Skipping icinga2 output; icinga2_host field is missing",
                   :missed_event => event)
      return
    end

    service = event.get("icinga2_service")
    if !service
      @logger.warn("Skipping icinga2 output; icinga2_service field is missing",
                   "missed_event" => event)
      return
    end

    annotation = event.get("icinga2_annotation")
    level = @icinga2_level

    if event.get("icinga2_level")
      event_level = [*event.get("icinga2_level")]
      case event_level[0].downcase
      when "ok"
        level = "0"
      when "warning"
        level = "1"
      when "critical"
        level = "2"
      when "unknown"
        level = "3"
      else
        @logger.warn("Invalid icinga2 level. Defaulting to CRITICAL", :data => event_level)
      end
    end

    cmd = "[#{Time.now.to_i}] PROCESS_SERVICE_CHECK_RESULT;#{host};#{service};#{level};#{message};"
    if annotation
      cmd += "#{annotation}: "
    end


    @logger.debug("Opening icinga2 command file", :commandfile => @commandfile,
                  :icinga2_command => cmd)
    begin
      send_to_icinga2(cmd)
    rescue => e
      @logger.warn("Skipping icinga2 output; error writing to command file",
                   :commandfile => @commandfile, :missed_event => event,
                   :exception => e, :backtrace => e.backtrace)
    end
  end # def receive

  def command_file_exist?
    File.exists?(@commandfile)
  end

  def send_to_icinga2(cmd)
    File.open(@commandfile, "r+") do |f|
      f.puts(cmd)
      f.flush # TODO(sissel): probably don't need this.
    end
  end
end # class LogStash::Outputs::icinga2