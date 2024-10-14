# frozen_string_literal: true

require_relative "light_tr/version"
require_relative "light_tr/config"
require_relative "light_tr/store"
require_relative "light_tr/translator"
require_relative "light_tr/chat_gpt"
require_relative "light_tr/runner"
require_relative "light_tr/commands"

module LightTr
  class Error < StandardError; end
end
