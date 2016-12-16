class TriggerHappyController < ApplicationController
  require 'github_manager'

  def index
  end

  def fetch_top_five
    organization = GithubManager::Organization.new(params[:username], params[:days])

    @repos = organization.repositories
    @results = organization.top_five

    render "trigger_happy/results"
  end
end
