class TriggerHappyController < ApplicationController
  require 'github_manager'

  def index
  end

  def create_org_tree
    begin
      @organization = GithubManager.create_org(params[:name])
      respond_to do |format|
        format.js {render layout: false}
      end
    rescue Exception => e
      @error = e
      puts e.message
      puts e.backtrace
      respond_to do |format|
        format.js {render 'trigger_happy/create_org_tree_error', layout: false}
      end
    end
  end

  def get_contributions_history
    begin
      @top_five = GithubManager.get_contributions_history(params[:days])
      respond_to do |format|
        format.js {render layout: false}
      end
    rescue Exception => e
      @error = e
      puts e.message
      puts e.backtrace
      respond_to do |format|
        format.js {render 'trigger_happy/contributions_error', layout: false}
      end
    end
  end
end
