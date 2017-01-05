module GithubManager
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
end
