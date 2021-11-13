# frozen_string_literal: true

module LightTr
  class Runner
    def initialize(store, translator)
      @store      = store
      @translator = translator
    end

    attr_reader :store, :translator

    def translate(target, text)
      store.load(target, text) || store.save(target, text, translator.translate(text, target))
    end
  end
end
