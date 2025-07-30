require_relative 'Plugin'
require 'net/http'
require 'nokogiri'
require 'uri'

class GithubRepoStarsCountPlugin < Plugin
    attr_reader :data, :repos
      
    def initialize(data)
        @data = data

        repos = {}
        data[0].each do |repo|
            repos[repo] = 0
        end
        @repos = repos
    end
    
    def execute
        
        repos.each do |repo, value|
            repos[repo] = load_repo_stars(repo)
        end

        return repos
    end

    def load_repo_stars(repo)
        uri = URI("https://github.com/#{repo}")

        response = Net::HTTP.get_response(uri)
        case response
        when Net::HTTPSuccess then
            document = Nokogiri::HTML(response.body)
            stargazers_count_element = document.at('span#repo-stars-counter-star')
            stargazers_count = stargazers_count_element&.text

            return stargazers_count || 0
        else
            return 0
        end
    end

end