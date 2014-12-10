module Hash19
  module Core
    extend ActiveSupport::Concern

    module Initializer
      def initialize(hash={})
        hash = hash.with_indifferent_access
        @hash19 = hash.slice(*self.class.keys)
        resolve_aliases if self.class.aliases.present?
        resolve_has_one(hash) if self.class.one_assocs.present?
        resolve_has_many(hash) if self.class.many_assocs.present?
      end

      private

      def resolve_aliases
        self.class.aliases.each do |key, as|
          @hash19[as] = @hash19.delete(key) if @hash19.has_key?(key)
        end
      end

      def resolve_has_one(hash)
        self.class.one_assocs.each do |name, opts|
          class_name = name.to_s.camelize
          association = hash[name]
          if association.present?
            klass = Module.const_get(class_name)
            @hash19[name] = klass.send(:new, association).to_h
          else
            @hash19[name] = opts[:trigger].call(@hash19.delete(opts[:using]))
          end
        end
      end

      def resolve_has_many(hash)
        self.class.many_assocs.each do |name, opts|
          class_name = name.to_s.camelize
          association = hash[name]
          if association.present?
            klass = Module.const_get(class_name)
            @hash19[name] = association.map { |hash| klass.send(:new, hash).to_h }
          else
            @hash19[name] = opts[:trigger].call(@hash19.delete(opts[:using]))
          end
        end
      end

    end

    def self.included(klass)
      klass.send :prepend, Initializer
    end

    def to_h
      @hash19
    end

    module ClassMethods

      attr_accessor :keys
      attr_accessor :aliases
      attr_accessor :one_assocs
      attr_accessor :many_assocs


      def attributes(*list)
        add_attributes(*list)
      end

      def attribute(name, opts = {})
        add_attributes(opts[:key] || name)
        add_aliases(opts[:key], name) if opts.has_key?(:key)
      end

      def has_one(name, opts = {})
        add_one_assoc(name, opts)
      end

      def has_many(name, opts = {})
        add_many_assoc(name, opts)
      end

      private

      def add_attributes(*list)
        @keys ||= []
        @keys += list
      end

      def add_aliases(name, alias_name)
        @aliases ||= {}
        @aliases[name] = alias_name
      end

      def add_one_assoc(name, opts)
        @one_assocs ||= {}
        @one_assocs[name] = opts
      end

      def add_many_assoc(name, opts)
        @many_assocs ||= {}
        @many_assocs[name] = opts
      end
    end
  end
end