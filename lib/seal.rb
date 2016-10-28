#!/usr/bin/env ruby

require './lib/github_fetcher.rb'
require './lib/message_builder.rb'
require './lib/slack_poster.rb'
require './lib/config.rb'

# Entry point for the Seal!
class Seal

  attr_reader :mode

  def initialize(organization, *team_names)
    @organization = organization
    @team_names = team_names
  end

  def bark
    today = Date.today
    postable_day = org_config.slack.weekends || (!today.saturday? && !today.sunday?)

    if postable_day
        org_config.teams.each { |team| bark_at(team) }
    else
        puts "Skipping slack posts for today"
    end
  end

  private

  attr_accessor :mood

  def teams
    if @team_names.empty?
      org_config.teams
    else
      @team_names.map { |name| team_config(name) }
    end
  end

  def bark_at(team)
    message_builder = MessageBuilder.new(team_params(team))
    message = message_builder.build

    slack = SlackPoster.new(org_config.slack,
                            team.channel,
                            message_builder.poster_mood)
    slack.send_request(message)
  end

  def org_config
    @org_config ||= SealConfig.new(@organization)
  end

  def team_params(team)
    return fetch_from_github(org_config.github, team) if @mode == nil
  end


  def fetch_from_github(config, team)
    git = GithubFetcher.new(config, team)
    git.list_pull_requests
  end

  def team_config(team)
      org_config.team(team)
  end
end
