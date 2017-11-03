module GithubManager
  class Commit
    attr_accessor :sha, :date, :message, :author_id

    def initialize(sha, date, message, author_id)
      @sha = sha
      @date = date
      @message = message
      @author_id = author_id
    end
  end
end
