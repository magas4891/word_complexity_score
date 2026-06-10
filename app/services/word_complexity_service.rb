class WordComplexityService < ApplicationService
  def initialize(word)
    @word = word
  end

  def call
    result = DictionaryApiService.call(@word)
    return failure(result.error) unless result.success?

    meanings = result.value.flat_map { |entry| entry["meanings"] || [] }
    return failure("No meanings found for '#{@word}'") if meanings.empty?

    definitions_count = meanings.sum { |m| (m["definitions"] || []).size }
    return failure("No definitions found for '#{@word}'") if definitions_count.zero?

    synonyms_count = meanings.sum do |m|
      (m["synonyms"] || []).size + (m["definitions"] || []).sum { |d| (d["synonyms"] || []).size }
    end

    antonyms_count = meanings.sum do |m|
      (m["antonyms"] || []).size + (m["definitions"] || []).sum { |d| (d["antonyms"] || []).size }
    end

    score = (synonyms_count + antonyms_count).to_f / definitions_count
    success(score.round(2))
  end
end
