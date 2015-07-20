require 'octokit'

module Firebots
  class GithubClient
    def initialize
      @client = Octokit::Client.new(
        login:    'frc3501bot',
        password: Konfiguration.creds(:github, :token))
    end

    def as_raw(repo:, path:, filename:)
      begin
        @client.contents("frc3501/#{repo}",
                         path: "#{path}/#{filename}",
                         accept: 'application/vnd.github.V3.raw')
      rescue Octokit::NotFound
        raise "\n\n## File not found: #{filename}"
      end
    end
  end
end
