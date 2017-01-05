module GithubManager
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
end
