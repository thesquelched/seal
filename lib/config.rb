require 'yaml'


class SealConfig

    attr_reader :github, :slack, :teams

    def initialize(organization)
        path = "./config/#{organization}.yml"
        raise IOError, 'File #{path} not found' unless File.exist? path
        data = YAML.load_file(path)

        github_data = data['github'] || {}
        github_data['organization'] = github_data['organization'] || organization
        @github = GithubConfig.new(**symbolic_hash(github_data))

        @slack = SlackConfig.new(**symbolic_hash(data['slack'] || {}))
        @teams = (data['teams'] or []).map do |item|
            item['channel'] = item['channel'] || @slack.channel
            TeamConfig.new(**symbolic_hash(item))
        end

        @team_map = @teams.map {|team| [team.name, team]}.to_h

    end

    def team(name)
        @team_map[name]
    end

end

private


def symbolic_hash(data)
    return data.inject({}) do |memo, (k, v)|
        memo[k.to_sym] = v;
        memo
    end
end


class GithubConfig

    attr_reader :organization, :api_url, :url, :access_token

    def initialize(organization: nil,
                   url: 'https://github.com',
                   api_url: 'https://api.github.com',
                   access_token: nil,
                   **args)
        raise ArgumentError, 'GitHub access token is required' if access_token.nil?

        @organization = organization
        @url = url.chomp('/')
        @api_url = api_url.chomp('/')
        @access_token = access_token
    end

end


class SlackConfig

    attr_reader :weekends, :webhook_url, :channel

    def initialize(webhook_url: nil,
                   channel: nil,
                   weekends: false,
                   **kwargs)
        @webhook_url = webhook_url
        @channel = channel
        @weekends = weekends
    end

end


class TeamConfig

    attr_reader :name, :members, :use_labels, :exclude_labels, :exclude_titles, :exclude_repos, :channel

    def initialize(name: nil,
                   members: nil,
                   use_labels: true,
                   exclude_labels: nil,
                   exclude_titles: nil,
                   exclude_repos: nil,
                   channel: nil,
                   **kwargs)
        raise ArgumentError, 'Team has no name' unless name
        raise ArgumentError, 'Team has no channel and no default exists' unless channel

        @name = name
        @members = members or []
        @use_labels = use_labels
        @exclude_labels = exclude_labels.uniq if exclude_labels
        @exclude_titles = exclude_titles.uniq.map{|item| to_regexp(item)} if exclude_titles
        @exclude_repos = exclude_repos.uniq.map{|item| to_regexp(item)} if exclude_repos
        @channel = channel
    end

    private
    
    def to_regexp(item)
        item.is_a?(Regexp) ? item : Regexp.new("^#{item}$")
    end

end


