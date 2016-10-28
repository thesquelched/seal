require 'octokit'

class GithubFetcher
  attr_accessor :people

  def initialize(config, team)
    @team = team.name
    @github = Octokit::Client.new(:access_token => config.access_token,
                                  :api_endpoint => config.api_url,
                                  :web_endpoint => config.url)
    @github.user.login
    @github.auto_paginate = true
    @people = team.members || []
    @use_labels = team.use_labels
    @exclude_labels = team.exclude_labels.map(&:downcase).uniq if team.exclude_labels
    @exclude_titles = team.exclude_titles
    @exclude_repos = team.exclude_repos
    @labels = {}
  end

  def list_pull_requests
    pull_requests_from_github.each_with_object({}) do |pull_request, pull_requests|
      repo_name = pull_request.html_url.split("/")[4]
      next if hidden?(pull_request, repo_name)
      pull_requests[pull_request.title] = present_pull_request(pull_request, repo_name)
    end
  end

  private

  attr_reader :use_labels, :exclude_labels, :exclude_titles, :exclude_repos

  def present_pull_request(pull_request, repo_name)
    pr = {}
    pr['title'] = pull_request.title
    pr['link'] = pull_request.html_url
    pr['author'] = pull_request.user.login
    pr['repo'] = repo_name
    pr['comments_count'] = count_comments(pull_request, repo_name)
    pr['thumbs_up'] = count_thumbs_up(pull_request, repo_name)
    pr['updated'] = Date.parse(pull_request.updated_at.to_s)
    pr['labels'] = labels(pull_request, repo_name)
    pr
  end

  # https://developer.github.com/v3/search/#search-issues
  # returns up to 100 results per page.
  def pull_requests_from_github
    @github.search_issues("is:pr state:open user:#{@team}").items
  end

  def person_subscribed?(pull_request)
    people.empty? || people.include?("#{pull_request.user.login}")
  end

  def count_comments(pull_request, repo)
    pr = @github.pull_request("#{@team}/#{repo}", pull_request.number)
    (pr.review_comments + pr.comments).to_s
  end

  def count_thumbs_up(pull_request, repo)
    response = @github.issue_comments("#{@team}/#{repo}", pull_request.number)
    comments_string = response.map {|comment| comment.body}.join
    thumbs_up = comments_string.scan(/:\+1:/).count.to_s
  end

  def labels(pull_request, repo)
    return [] unless use_labels
    key = "#{@team}/#{repo}/#{pull_request.number}".to_sym
    @labels[key] ||= @github.labels_for_issue("#{@team}/#{repo}", pull_request.number)
  end

  def hidden?(pull_request, repo)
    excluded_repo?(repo) ||
      excluded_label?(pull_request, repo) ||
      excluded_title?(pull_request.title) ||
      !person_subscribed?(pull_request)
  end

  def excluded_label?(pull_request, repo)
    return false unless exclude_labels
    lowercase_label_names = labels(pull_request, repo).map { |l| l['name'].downcase }
    exclude_labels.any? { |e| lowercase_label_names.include?(e) }
  end

  def excluded_title?(title)
    exclude_titles && exclude_titles.any? { |rgx| rgx.match(title) }
  end

  def excluded_repo?(repo)
    exclude_repos && exclude_repos.any? { |rgx| rgx.match(repo) }
  end
end
