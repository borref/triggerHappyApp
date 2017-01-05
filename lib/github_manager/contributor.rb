module GithubManager
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
end
