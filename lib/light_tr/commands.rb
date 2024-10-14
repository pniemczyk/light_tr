# frozen_string_literal: true
require 'fileutils'
require 'lockbox'
require 'light_tr/chat_gpt'

module LightTr
  class Commands
    SUPPORTED_LANGUAGES = %w[
      af ga sq it ar ja az kn eu ko bn la be lv bg lt ca mk ms mt hr no cs fa da pl nl pt en ro eo
      ru et sr tl sk fi sl fr es gl sw ka sv de ta el te gu th ht tr iw uk hi ur hu vi is cy id yi
      zh-CN zh-TW
    ]
    COMMANDS_MAPPING = {
      '-config' => 'update_config',
      '-show_config' => 'show_config',
      '-clear_cache' => 'clear_cache',
      '-supported_languages' => 'supported_languages',
      '-help' => 'help'
    }

    def self.command?(command)
      COMMANDS_MAPPING.include?(command)
    end

    def self.command_runner(command)
      method_name = COMMANDS_MAPPING[command]
      send(method_name)
      print_footer
    end

    def self.print_footer
      puts "\nLight Translate © 2021 by Paweł Niemczyk"
    end

    def self.help
      puts "usage: trans [options] any sentence"
      puts "\noptions:"
      puts '  -config      : init configuration'
      puts '  -show_config : show configuration'
      puts '  -clear_cache : clear translation cache [only for google provider]'
      puts '  -pl          : translate only one language (pl can be changed on any supported language) [only for google provider]'
      puts '  -i           : run translator in interactive mode'
    end

    def self.clear_cache
      cache_file = File.join(::LightTr::Config.config_path, 'tanslations.yml')
      File.delete(cache_file) if File.exist?(cache_file)
      puts 'Cache cleared !!!'
    end

    def self.show_config
      api_key = ::LightTr::Config.api_key
      show_key = api_key[..10] + ('*' * (api_key.size - 10))
      puts 'Current configuration:'
      puts "\nlanguages                : #{::LightTr::Config.languages}"
      puts "Goggle Translate API key : #{show_key}\n"
      puts "OpenAI API key           : #{::LightTr::Config.open_ai_key}"
      puts "Provider                 : #{::LightTr::Config.provider}"
      puts "Model                    : #{::LightTr::Config.model}"
    end

    def self.supported_languages
      puts 'Supported languages (codes):'
      puts SUPPORTED_LANGUAGES.join(', ')
    end

    def self.languages_valid?(languages)
      prepare_languages(languages).all? do |code|
        SUPPORTED_LANGUAGES.include?(code)
      end
    end

    def self.languages_errors_and_update_config(languages)
      prepare_languages(languages).each do |code|
        puts "Incorrect language code: #{code}" unless SUPPORTED_LANGUAGES.include?(code)
      end
      puts "\n"
      supported_languages
      puts "\nTry again :D\n\n"
      update_config
    end

    def self.prepare_languages(value)
      value.to_s.split(',').map(&:strip).compact
    end

    def self.default_model
      'gpt-3.5-turbo'
    end

    def self.update_config
      FileUtils.mkdir_p(::LightTr::Config.config_path) unless File.directory?(::LightTr::Config.config_path)
      puts 'Hello my friend lets setup Light Translator now!'
      puts 'We will need only two things, Google Translate API key and your favorite languages'
      puts "When you complete setup in your home directory will be created .light_tr/.config file with encrypted configuration"
      puts "\n"
      puts "\nYou can use two providers and set which one will be default: 'google' or 'openai'"
      puts "\nLet's add Google Translate API key first. Instructions on: https://cloud.google.com/translate/docs/quickstarts"
      print 'Give me the Google Translate API key: (empty to skip) '
      api_key = STDIN.gets.chomp

      puts "\n"
      puts "\nYou can choice multiple languages example: pl, en, ru"
      puts "\nBut openia provider support only two languages because it's working a little bit differently."
      puts "\nIt is detecting source language and translate to target language automatically. For example: pl, en"
      puts "\n`Jak się dziś masz?` -> `How are you today?`"
      print 'Give me languages: '
      languages = prepare_languages(STDIN.gets.chomp).join(', ')

      puts "\n"
      puts "\nLet's add OpenAI API key now. Instructions on: https://platform.openai.com/api-keys"
      print 'Give me the OpenAI API key key: (empty to skip) '
      open_ai_api_key = STDIN.gets.chomp
      models = open_ai_api_key.empty? ? [default_model] : ::LightTr::ChatGpt.new(open_ai_api_key).models
      model = unless open_ai_api_key.empty?
                puts "\n"
                puts "\nLet's choice model for OpenAI. Default is (gpt-4o-mini)"
                puts "\nAll available models:"
                models.each { |m| puts m }

                print 'Give me the model: (default is gpt-3.5-turbo) '
                STDIN.gets.chomp
              end

      model = models.include?(model) ? model : default_model

      puts "\n"
      puts "\n Now let's set default provider. You can choice between 'google' and 'openai' (default is google if present)"
      print 'Give me the provider: (you can use just letters g, o)'
      provider = STDIN.gets.chomp
      if %w[g google].include?(provider.downcase) && !api_key.empty?
        provider = 'google'
      elsif %w[o openai].include?(provider.downcase) && !open_ai_api_key.empty?
        provider = 'openai'
      else
        provider = 'google'
      end

      puts "\nYour configuration is:"
      puts "Google API key: #{api_key}"
      puts "OpenAI API key: #{open_ai_api_key}"
      puts "OpenAI model: #{model.empty? ? default_model : model}"
      puts "Provider: #{provider}"
      puts "languages: #{languages}\n\n"

      return languages_errors_and_update_config(languages) unless languages_valid?(languages)

      print "It's correct? (y/n/q): "
      answer = STDIN.gets.chomp

      return update_config if answer.strip == 'n'
      return puts 'Bye Bye !' if answer.strip == 'q'

      master_key = Lockbox.generate_key
      ::LightTr::Config.set({ 'master_key' => master_key })
      ::LightTr::Config.set({ 'api_key' => Lockbox.new(key: master_key).encrypt(api_key.strip) })
      ::LightTr::Config.set({ 'languages' => languages.strip })
      ::LightTr::Config.set({ 'open_ai_key' => Lockbox.new(key: master_key).encrypt(open_ai_api_key.strip) })
      ::LightTr::Config.set({ 'provider' => provider.strip })
      ::LightTr::Config.set({ 'model' => (model.empty? ? default_model : model).strip })

      puts "\nHappy translating!"
    end
  end
end
