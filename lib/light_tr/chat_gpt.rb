# frozen_string_literal: true

require 'faraday'
require 'faraday/mashify'

module LightTr
  class ChatGpt
    SUPPORTED_LANGUAGES_MAP = { 'af' => 'Afrikaans', 'ga' => 'Irish', 'sq' => 'Albanian', 'it' => 'Italian', 'ar' => 'Arabic', 'ja' => 'Japanese', 'az' => 'Azerbaijani', 'kn' => 'Kannada', 'eu' => 'Basque', 'ko' => 'Korean', 'bn' => 'Bengali', 'la' => 'Latin', 'be' => 'Belarusian', 'lv' => 'Latvian', 'bg' => 'Bulgarian', 'lt' => 'Lithuanian', 'ca' => 'Catalan', 'mk' => 'Macedonian', 'ms' => 'Malay', 'mt' => 'Maltese', 'hr' => 'Croatian', 'no' => 'Norwegian', 'cs' => 'Czech', 'fa' => 'Persian', 'da' => 'Danish', 'pl' => 'Polish', 'nl' => 'Dutch', 'pt' => 'Portuguese', 'en' => 'English', 'ro' => 'Romanian', 'eo' => 'Esperanto', 'ru' => 'Russian', 'et' => 'Estonian', 'sr' => 'Serbian', 'tl' => 'Filipino', 'sk' => 'Slovak', 'fi' => 'Finnish', 'sl' => 'Slovenian', 'fr' => 'French', 'es' => 'Spanish', 'gl' => 'Galician', 'sw' => 'Swahili', 'ka' => 'Georgian', 'sv' => 'Swedish', 'de' => 'German', 'ta' => 'Tamil', 'el' => 'Greek', 'te' => 'Telugu', 'gu' => 'Gujarati', 'th' => 'Thai', 'ht' => 'Haitian Creole', 'tr' => 'Turkish', 'iw' => 'Hebrew', 'uk' => 'Ukrainian', 'hi' => 'Hindi', 'ur' => 'Urdu', 'hu' => 'Hungarian', 'vi' => 'Vietnamese', 'is' => 'Icelandic', 'cy' => 'Welsh', 'id' => 'Indonesian', 'yi' => 'Yiddish', 'zh-CN' => 'Chinese (Simplified)', 'zh-TW' => 'Chinese (Traditional)' }.freeze # rubocop:disable Layout/LineLength

    def initialize(api_key, model = 'gpt-3.5-turbo')
      @api_key = api_key
      @model = model
    end

    def translate(query, languages)
      completion(query, languages)
    end

    def models
      @models ||= client.get('models').body.data.map(&:id).select { |id| id.include?('gpt') }
    end

    private

    attr_reader :api_key, :model

    def system(languages)
      langs = languages.map { |lang| SUPPORTED_LANGUAGES_MAP[lang] }
      intro = if langs.count == 1
                "You are a translator, everything you receive next should be translated into #{langs[0]}."
              else
                "You are a translator, everything you receive next should be translated into #{langs[0]} or #{langs[1]}.\nIf the given text is in #{langs[1]}, translate it into #{langs[0]}.\nIf the text is in #{langs[0]}, translate it into #{langs[1]}." # rubocop:disable Layout/LineLength
              end
      intro + "\nTry to translate in a way that sounds natural to a native speaker of that language.\nOnly return the translation of the text; you don’t need to translate the code." # rubocop:disable Layout/LineLength
    end

    def completion(query, languages)
      client.post(
        'chat/completions', {
        model: model,
        temperature: 0.7,
        messages: [
          { role: 'system', content: system(languages) },
          { role: 'user', content: query }
        ] }
      ).body.choices[0].message.content
    end

    def client
      @client ||= Faraday.new(url: 'https://api.openai.com/v1') do |faraday|
        faraday.request :authorization, 'Bearer', api_key
        faraday.request :json
        faraday.response :mashify
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
