require 'RESTClient'
require 'date'

module GithubManager
  include RESTClient
  @@current_organization = {}
  RESTClient.set_base_url("https://api.github.com")

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
