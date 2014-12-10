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
        perform_injections(@hash19) if self.class.injections.present?
      end

      private

      def resolve_has_one(hash)
        resolve_associations(hash, self.class.one_assocs, :one)
      end

      def resolve_has_many(hash)
        resolve_associations(hash, self.class.many_assocs, :many)
      end

      def resolve_associations(hash, associations, type)
        associations.each do |name, opts|
          class_name = name.to_s.camelize
          association = hash[opts[:key] || name]
          @hash19[opts[:alias] || name] = if association.present?
                                            klass = resolve_class(class_name.singularize)
                                            if type == :one
                                              klass.send(:new, association).to_h
                                            else
                                              association.map { |hash| klass.send(:new, hash).to_h }
                                            end
                                          else
                                            raise "Not key with name:<#{name}> present. Possible specify a trigger" unless opts[:trigger]
                                            opts[:trigger].call(@hash19.delete(opts[:using]))
                                          end
        end
      end

      def resolve_aliases
        self.class.aliases.each do |key, as|
          @hash19[as] = @hash19.delete(key) if @hash19.has_key?(key)
        end
      end

      def perform_injections(hash)
        self.class.injections.each do |opts|
          JsonPath.for(hash).gsub!(opts[:at]) do |entries|
            ids = entries.map { |el| el[opts[:using]] }
            to_inject = opts[:trigger].call(ids)
            key = opts[:using].to_s.gsub(/_id/,'')
            entries.each do |entry|
              id = entry.delete(opts[:using])
              target = to_inject.find { |el| el[opts[:reference] || opts[:using]] == id }
              entry[key] = target
            end
            entries
          end
        end
      end

    end

    def resolve_class(assoc_name)
      full_class_name = self.class.name
      new_class = full_class_name.gsub(full_class_name.demodulize, assoc_name)
      new_class.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
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
      attr_accessor :injections

      def attributes(*list)
        add_attributes(*list)
      end

      def attribute(name, opts = {})
        add_attributes(opts[:key] || name)
        @aliases ||= {}
        @aliases[opts[:key]] = name  if opts.has_key?(:key)
      end

      def has_one(name, opts = {})
        @one_assocs ||= {}
        @one_assocs[name] = opts
      end

      def has_many(name, opts = {})
        @many_assocs ||= {}
        @many_assocs[name] = opts
      end

      def inject(opts)
        @injections ||= []
        @injections << opts
      end

      private

      def add_attributes(*list)
        @keys ||= []
        @keys += list
      end

    end
  end
end