require 'scorched/collection'

module GitPeer::Context

  class Error < Exception; end

  module Configurable

    def self.included(mod)
      mod.class_eval do
        include Scorched::Collection :declarations
      end
      mod.extend ClassMethods
    end

    module ClassMethods

      def declare(name, **declaration)
        declarations << declaration.merge(declaration: name)
      end

      def inject(configurable)
        declarations << configurable
      end

      def all_declarations
        declarations.map do |d|
          if d.is_a? Class and d < Configurable
            d.all_declarations
          else
            {declaration: d, configurable: self}
          end
        end.flatten(1)
      end

    end

  end

  def self.included(mod)
    mod.extend ClassMethods
    Configurable.included(mod)
  end

  module ClassMethods

    def configure!
      all_declarations.each do |declaration|
        self.process declaration[:declaration], declaration[:configurable]
      end
    end

    def process(d, c)
      processor_name = "process_#{d[:declaration]}".to_sym
      if self.respond_to? processor_name
        self.send processor_name, d, c
      else
        raise Error.new("don't know how to process '#{d[:declaration]}'")
      end
    end

  end

end
