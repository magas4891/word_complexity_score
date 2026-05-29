require "rails_helper"

RSpec.describe DictionaryApiService do
  let(:word) { "happy" }
  let(:api_url) { "https://api.dictionaryapi.dev/api/v2/entries/en/#{word}" }

  let(:api_response) do
    [
      {
        "meanings" => [
          {
            "partOfSpeech" => "adjective",
            "definitions" => [
              { "definition" => "Feeling joy.", "synonyms" => [ "joyful" ], "antonyms" => [ "sad" ] }
            ],
            "synonyms" => [ "glad" ],
            "antonyms" => [ "unhappy" ]
          }
        ]
      }
    ].to_json
  end

  describe ".call" do
    context "when the API returns a successful response" do
      before do
        stub_request(:get, api_url).to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })
      end

      it "returns a success result" do
        result = described_class.call(word)
        expect(result.success?).to be true
      end

      it "returns parsed JSON as value" do
        result = described_class.call(word)
        expect(result.value).to be_an(Array)
        expect(result.value.first["meanings"]).to be_present
      end
    end

    context "when the word is not found" do
      before do
        stub_request(:get, api_url).to_return(status: 404, body: '{"title":"No Definitions Found"}')
      end

      it "returns a failure result" do
        result = described_class.call(word)
        expect(result.success?).to be false
      end

      it "includes the word in the error message" do
        result = described_class.call(word)
        expect(result.error).to include(word)
      end
    end

    context "when the API returns a server error" do
      before do
        stub_request(:get, api_url).to_return(status: 500, body: "Internal Server Error")
      end

      it "returns a failure result" do
        result = described_class.call(word)
        expect(result.success?).to be false
        expect(result.error).to include("500")
      end
    end

    context "when a network error occurs" do
      before do
        stub_request(:get, api_url).to_raise(SocketError.new("Failed to connect"))
      end

      it "returns a failure result" do
        result = described_class.call(word)
        expect(result.success?).to be false
        expect(result.error).to include("Failed to connect")
      end
    end
  end
end
