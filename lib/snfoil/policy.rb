# frozen_string_literal: true

require 'active_support/concern'

module SnFoil
  # ActiveSupport::Concern for adding SnFoil Policy functionality to policy file
  #
  # @author Matthew Howes
  #
  # @since 0.1.0
  module Policy
    class Error < RuntimeError; end

    extend ActiveSupport::Concern

    class_methods do
      def i_permissions
        @i_permissions ||= {}
      end

      def permission(authorization_type, entity_class = nil, with: nil, &block)
        @i_permissions ||= {}
        @i_permissions[authorization_type] ||= {}
        if @i_permissions[authorization_type][entity_class]
          raise SnFoil::Policy::Error,
                "permission #{entity_class} #{authorization_type} already defined for #{name}"
        end

        @i_permissions[authorization_type][entity_class] = build_permission_exec(with, block)
        define_permission_method(authorization_type)
      end
    end

    attr_reader :record, :entity
    attr_accessor :options

    def initialize(entity, record, options = {})
      @record = record
      @entity = entity
      @options = options
    end

    # Default Scope class for associated Policies.
    #
    # @author Matthew Howes
    #
    # @since 0.1.0
    class Scope
      attr_reader :scope, :entity

      def initialize(scope, entity = nil)
        @entity = entity
        @scope = scope
      end

      def resolve
        scope
      end
    end

    private

    class_methods do
      def build_permission_exec(method, block)
        return block if block

        proc { send(method) }
      end

      def define_permission_method(authorization_type)
        define_method authorization_type do
          self.class.i_permissions[authorization_type].each do |klass, exec|
            return instance_eval(&exec) if klass.nil? || entity.is_a?(klass)
          end

          false
        end
      end
    end
  end
end
