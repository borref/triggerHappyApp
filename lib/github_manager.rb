require 'RESTClient'
require 'date'

module GithubManager
  include RESTClient

  @@current_organization = {}

  RESTClient.set_base_url("https://api.github.com")

  class Organization
    attr_accessor :login_name, :repositories, :avatar_url, :repos_url, :collaborators
    def initialize(login_name, avatar_url, repos_url)
      @login_name = login_name
      @repos_url = repos_url
      @avatar_url = avatar_url
      @collaborators = []
      @repositories = fetch_repos
    end

    def top_five_collaborators(days_ago)
      @collaborators.each { |collaborator| collaborator.contributions_number = 0 }
      @repositories.each { |repo| repo.fetch_commits_from days_ago }

      top_five_collaborators = @collaborators.sort_by { |col| col.contributions_number }.reverse![0..4].select { |col| col.contributions_number > 0 }
      top_five_collaborators.each { |col| col.avg_contributions = '%.2f' % (col.contributions_number / days_ago.to_f) }
    end

    def fetch_repos
      fetched_repos = []

      response = RESTClient.make_request('GET', "/orgs/#{@login_name}/repos",
                                          { :page => 1, :per_page => 100 })

      if response
        loop do
          parsed_response = JSON.parse response.body

          parsed_response.each do |repo|
            fetched_repos << Repository.new(repo['name'])
          end

          if response.next_page_url
            response = RESTClient.make_request('GET', response.next_page_url)
          else
            break
          end
        end
      else
        raise "There was a problem fetching the organization repos"
      end

      fetched_repos
    end
  end

  class Repository

    attr_accessor :name, :commits, :contributions

    def initialize(name)
      @name = name
      @collaborators = []
      @contributions = Hash.new(0)
      @commits = []
    end

    private

    def fetch_commits_from(days_ago)
      start_date = DateTime.now - days_ago.to_i

      @commits = []
      response = RESTClient.make_request('GET', "/repos/#{GithubManager.current_organization.login_name}/#{@name}/commits",
                                          { :since => start_date, :page => 1, :per_page => 100 })

      if response
        loop do
          parsed_response = JSON.parse response.body

          parsed_response.each do |commit|
            author = commit['author'] ? commit['author'] : commit['commit']['author']

            commit_author_id = author['id'] ? author['id'] : author['email']
            found_collaborator = GithubManager.current_organization.collaborators.find { |collaborator| collaborator.id == commit_author_id }

            if found_collaborator
              found_collaborator.contributions_number += 1
            else
              if author['id']
                GithubManager.current_organization.collaborators << Contributor.new(author['id'], author['login'],
                                                                                    author['avatar_url'], author['html_url'])
              else
                GithubManager.current_organization.collaborators << Contributor.new(author['email'], author['name'], '', '')
              end
            end

            @commits << Commit.new(commit['sha'], commit['commit']['author']['date'], commit['commit']['message'], commit_author_id)
          end

          if response.next_page_url
            response = RESTClient.make_request('GET', response.next_page_url)
          else
            break
          end
        end
      else
        raise "There was a problem fetching the organization commits"
      end
    end
  end

  class Commit
    attr_accessor :sha, :date, :message, :author_id

    def initialize(sha, date, message, author_id)
      @sha = sha
      @date = date
      @message = message
      @author_id = author_id
    end
  end

  class Contributor
    attr_accessor :id, :username, :avatar_url, :profile_url, :contributions_number, :avg_contributions

    def initialize(id, username, avatar_url, profile_url)
      @id = id
      @username = username
      @avatar_url = avatar_url
      @profile_url = profile_url
      @contributions_number = 1
      @avg_contributions = 0
    end
  end

  def current_organization
    @@current_organization
  end

  def create_org(name)
    response = RESTClient.make_request('GET', "/orgs/#{name}")

    if response
      parsed_response = JSON.parse response.body
      @@current_organization = Organization.new(parsed_response['login'], parsed_response['avatar_url'],
                                                parsed_response['repos_url'].split('com')[1])
    else
      raise "Couldn't find a organization with the provided name"
    end
  end

  def get_contributions_history(days_ago)
    @@current_organization.top_five_collaborators days_ago
  end

  module_function :create_org, :current_organization, :get_contributions_history
end
