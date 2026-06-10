require "rails_helper"

RSpec.describe WordComplexityService do
  let(:word) { "happy" }

  let(:api_data) do
    [
      {
        "meanings" => [
          {
            "partOfSpeech" => "adjective",
            "definitions" => [
              { "definition" => "Feeling joy.", "synonyms" => [ "joyful" ], "antonyms" => [ "sad" ] },
              { "definition" => "Fortunate.", "synonyms" => [], "antonyms" => [] }
            ],
            "synonyms" => [ "glad", "content" ],
            "antonyms" => [ "unhappy" ]
          }
        ]
      }
    ]
  end

  describe ".call" do
    context "when the word is found" do
      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: true, value: api_data, error: nil))
      end

      it "returns a success result" do
        result = described_class.call(word)
        expect(result.success?).to be true
      end

      it "calculates score correctly" do
        # synonyms: 2 (meaning level) + 1 (definition level) = 3
        # antonyms: 1 (meaning level) + 1 (definition level) = 2
        # definitions: 2
        # score = (3 + 2) / 2 = 2.5
        result = described_class.call(word)
        expect(result.value).to eq(2.5)
      end
    end

    context "when the word has no synonyms or antonyms" do
      let(:empty_api_data) do
        [
          {
            "meanings" => [
              {
                "partOfSpeech" => "noun",
                "definitions" => [ { "definition" => "A thing.", "synonyms" => [], "antonyms" => [] } ],
                "synonyms" => [],
                "antonyms" => []
              }
            ]
          }
        ]
      end

      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: true, value: empty_api_data, error: nil))
      end

      it "returns score of 0.0" do
        result = described_class.call(word)
        expect(result.value).to eq(0.0)
      end
    end

    context "when the dictionary API fails" do
      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: false, value: nil, error: "Word '#{word}' not found"))
      end

      it "returns a failure result" do
        result = described_class.call(word)
        expect(result.success?).to be false
        expect(result.error).to include(word)
      end
    end

    context "when meanings/definitions are missing synonyms or antonyms keys" do
      let(:sparse_api_data) do
        [
          {
            "meanings" => [
              {
                "partOfSpeech" => "noun",
                "definitions" => [ { "definition" => "A thing." } ]
              }
            ]
          }
        ]
      end

      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: true, value: sparse_api_data, error: nil))
      end

      it "treats missing synonyms/antonyms as empty and returns 0.0" do
        result = described_class.call(word)
        expect(result.success?).to be true
        expect(result.value).to eq(0.0)
      end
    end

    context "when a meaning has no definitions key" do
      let(:no_definitions_api_data) do
        [
          {
            "meanings" => [
              { "partOfSpeech" => "noun", "synonyms" => [ "thing" ], "antonyms" => [] }
            ]
          }
        ]
      end

      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: true, value: no_definitions_api_data, error: nil))
      end

      it "returns a failure result for no definitions found" do
        result = described_class.call(word)
        expect(result.success?).to be false
        expect(result.error).to include("No definitions found")
      end
    end

    context "when the API returns no meanings" do
      before do
        allow(DictionaryApiService).to receive(:call).with(word)
          .and_return(ApplicationService::Result.new(success?: true, value: [ { "meanings" => [] } ], error: nil))
      end

      it "returns a failure result" do
        result = described_class.call(word)
        expect(result.success?).to be false
        expect(result.error).to include("No meanings found")
      end
    end
  end
end
