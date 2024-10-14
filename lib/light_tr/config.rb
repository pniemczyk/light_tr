# frozen_string_literal: true
require 'yaml'
require 'fileutils'
require 'lockbox'

module LightTr
  class Config
    class SetConfigError < StandardError; end

    def self.languages
      get['languages']
    end

    def self.open_ai_key
      get['open_ai_key'] || raise('OpenAI API key missing. Try to update configuration via `trans -config`')
      master_key = get['master_key'] || raise('Config file corrupted. Try to update configuration via `trans -config`')
      Lockbox.new(key: master_key).decrypt(get['open_ai_key'])
    end

    def self.api_key
      get['api_key'] || raise('Google Translation API key missing. Try to update configuration via `trans -config`')
      master_key = get['master_key'] || raise('Config file corrupted. Try to update configuration via `trans -config`')
      Lockbox.new(key: master_key).decrypt(get['api_key'])
    end

    def self.provider
      get['provider'] || 'google'
    end

    def self.model
      get['model'] || 'gpt-3.5-turbo'
    end

    def self.config_path
      File.join(Dir.home, '.light_tr')
    end

    def self.config_exists?
      File.exists?(config_file)
    end

    def self.config_missing?
      !config_exists?
    end

    def self.config_file
      File.expand_path('.config', config_path)
    end

    def self.get
      return load_configuration if config_exists?

      {}
    end

    def self.set(hash)
      raise SetConfigError, 'argument is not kind of hash' unless hash.kind_of?(Hash)

      updated_config = get.merge(hash)
      save_configuration(updated_config)
    end

    def self.clear
      File.write(config_file, {}.to_yaml)
    end

    private

    def self.save_configuration(config)
      File.write(config_file, config.to_yaml)
    end

    def self.load_configuration
      YAML.load_file(config_file)
    rescue
      {}
    end
  end
end
