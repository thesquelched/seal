require 'slack-poster'

class SlackPoster

  attr_accessor :webhook_url, :poster, :mood, :mood_hash, :channel, :season_name, :halloween_season, :festive_season

  def initialize(config, team_channel, mood, dryrun: false)
    @webhook_url = config.webhook_url
    @team_channel = team_channel
    @mood = mood
    @today = Date.today
    @postable_day = config.weekends || (!today.saturday? && !today.sunday?)
    @dryrun = dryrun

    mood_hash
    create_poster
  end

  def create_poster
    @poster = Slack::Poster.new(webhook_url, slack_options)
  end

  def send_request(message)
    if @dryrun
      puts "Will#{' not' unless postable_day} post #{mood} message to #{team_channel} on #{today.strftime('%A')}"
      puts slack_options.inspect
      puts message
    else
      poster.send_message(message) if postable_day
    end
  end

  private

  attr_reader :postable_day, :today

  def slack_options
    {
     icon_emoji: @mood_hash[:icon_emoji],
     username: @mood_hash[:username],
     channel: @team_channel
   }
  end

  def mood_hash
    @mood_hash = {}
    check_season
    assign_poster_settings
  end

  def assign_poster_settings
    if @mood == "informative"
      @mood_hash[:icon_emoji]= ":#{@season_symbol}informative_seal:"
      @mood_hash[:username]= "#{@season_name}Informative Seal"
    elsif @mood == "approval"
      @mood_hash[:icon_emoji]= ":#{@season_symbol}seal_of_approval:"
      @mood_hash[:username]= "#{@season_name}Seal of Approval"
    elsif @mood == "angry"
      @mood_hash[:icon_emoji]= ":#{@season_symbol}angrier_seal:"
      @mood_hash[:username]= "#{@season_name}Angry Seal"
    elsif @mood == "tea"
      @mood_hash[:icon_emoji]= ":manatea:"
      @mood_hash[:username]= "Tea Seal"
    elsif @mood == "charter"
      @mood_hash[:icon_emoji]= ":happyseal:"
      @mood_hash[:username]= "Team Charter Seal"
    else
      fail "Bad mood: #{mood}."
    end
  end

  def check_season
    if halloween_season?
      @season_name = "Halloween "
    elsif festive_season?
      @season_name = "Festive Season "
    else
      @season_name = ""
    end
    @season_symbol = snake_case(@season_name)
  end

  def halloween_season?
    this_year = today.year
    today <= Date.new(this_year, 10, 31) && today >= Date.new(this_year,10,23)
  end

  def festive_season?
    this_year = today.year
    return true if today <= Date.new(this_year, 12, 31) && today >= Date.new(this_year,12,1)
    today == Date.new(this_year, 01, 01)
  end

  def snake_case(string)
    string.downcase.gsub(" ", "_")
  end

end
