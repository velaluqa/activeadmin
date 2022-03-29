# coding: utf-8
require "active_support/concern"

module ConfigurationPathAccessor
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    NO_DEFAULT_PROVIDED = Object.new
    SERVICE_ATTRIBUTES = %i(default user_provided_default).freeze
    private_constant :NO_DEFAULT_PROVIDED

    def attr_configuration_path_accessor(name, path, default: nil)
      define_attribute_reader(name, path, default)
      define_attribute_writer(name, path)
    end

    def define_attribute_reader(name, path, default)
      wrapper = Module.new do
        define_method name do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")

          value =
            begin
              if configuration
                configuration.data.dig(*path) || default
              else
                default
              end
            end

          instance_variable_set("@#{name}", value)
        end
      end
      include wrapper
    end

    def define_attribute_writer(name, path)
      wrapper = Module.new do
        define_method "#{name}=" do |val|
          instance_variable_set("@#{name}", val)
          instance_variable_set("@configuration_dirty", true)
        end
      end
      include wrapper
    end
  end
end
