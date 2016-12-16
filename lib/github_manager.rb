require 'RESTClient'
require 'date'

module GithubManager

  include RESTClient

  RESTClient.set_base_url("https://api.github.com")
  
  class Organization

    attr_accessor :username, :repositories, :results

    # Builder
    def initialize(username, days)
      @username = username
      @results = Hash.new(0)
      @repositories = fetch_repos(days)      
    end

    # Return the five devs with more contributions
    def top_five
      @results.max_by(5, &:last).to_h
    end

    private
      # Fetch all organization repositories
      def fetch_repos(days)
        fetched_repos = []
        start_day = DateTime.now - days.to_i

        response = RESTClient.make_request('GET', "/orgs/#{@username}/repos")

        if response
          parsed_response = JSON.parse response.response_body
          
          parsed_response.each do |repo|
            created_repo = Repository.new(repo['full_name'], start_day) if repo
            fetched_repos << created_repo
            @results.merge!(created_repo.contributions) { |key, v1, v2| v1 + v2 }
          end
        else
          puts "\n\nERROR\n\n"
          p response
        end
          
        fetched_repos
      end
  end

  class Repository

    attr_accessor :name, :commits, :contributions

    # Builder
    def initialize(name, start_day)
      @name = name
      @contributions = Hash.new(0)
      @commits = fetch_commits(start_day)
    end

    private
      def fetch_commits(start_day)
        fetched_commits = []
        response = RESTClient.make_request('GET', "/repos/#{@name}/commits", { :since => start_day })

        if response
          parsed_response = JSON.parse response.response_body
          
          parsed_response.each do |commit|
            author = commit['commit']['author']
            fetched_commits << Commit.new(commit['sha'], author['date'],
                                          commit['commit']['message'], author['name']) if commit
            @contributions[author['name']] += 1
          end
        else
          puts "\n\nERROR\n\n"
          p response
        end
          
        fetched_commits
      end
  end

  class Commit

    attr_accessor :sha, :date, :message, :author_name

    # Builder
    def initialize(sha, date, message, author_name)
      @sha = sha
      @date = date
      @message = message
      @author_name = author_name
    end
  end

end