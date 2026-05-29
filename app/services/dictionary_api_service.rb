require "net/http"
require "json"

class DictionaryApiService < ApplicationService
  BASE_URL = "https://api.dictionaryapi.dev/api/v2/entries/en"

  def initialize(word)
    @word = word
  end

  def call
    response = fetch

    case response
    when Net::HTTPSuccess
      success(JSON.parse(response.body))
    when Net::HTTPNotFound
      failure("Word '#{@word}' not found")
    else
      failure("API error: #{response.code} #{response.message}")
    end
  rescue StandardError => e
    failure(e.message)
  end

  private

  def fetch
    uri = URI("#{BASE_URL}/#{URI.encode_uri_component(@word)}")
    Net::HTTP.get_response(uri)
  end
end
