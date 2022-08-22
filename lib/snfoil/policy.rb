# frozen_string_literal: true

# Copyright 2021 Matthew Howes, Cliff Campbell

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
      def snfoil_permissions
        @snfoil_permissions ||= {}
      end

      def permission(authorization_type, entity_class = nil, with: nil, &block)
        @snfoil_permissions ||= {}
        @snfoil_permissions[authorization_type] ||= {}
        @snfoil_permissions[authorization_type][entity_class] = build_permission_exec(with, block)
        define_permission_method(authorization_type)
      end

      def inherited(subclass)
        super

        instance_variables.grep(/@snfoil_.+/).each do |i|
          subclass.instance_variable_set(i, instance_variable_get(i).dup)
        end
      end
    end

    attr_reader :record, :entity
    attr_accessor :options

    def initialize(entity, record, **options)
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
          self.class.snfoil_permissions[authorization_type].each do |klass, exec|
            return instance_eval(&exec) if klass.nil? || entity.is_a?(klass)
          end

          false
        end
      end
    end
  end
end
