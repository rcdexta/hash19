module Hash19
  module Core

    extend ActiveSupport::Concern

    module ClassMethods
      include Hash19::CoreHelpers
    end

    include Hash19::Resolvers

    module Initializer
      def initialize(payload={})
        if self.class.contains_klass
          @hash19 = payload.map do |el|
            klass = resolve_class(self.class.contains_klass.to_s.camelize.singularize)
            klass.send(:new, el).to_h
          end
        else
          hash = payload.with_indifferent_access
          @hash19 = hash.slice(*self.class.keys)
          resolve_aliases if self.class.aliases.present?
          resolve_has_one(hash) if self.class.one_assocs.present?
          resolve_has_many(hash) if self.class.many_assocs.present?
        end
        resolve_injections(@hash19) if self.class.injections.present?
      end
    end

    def self.included(klass)
      klass.send :prepend, Initializer
    end

    def to_h
      @hash19.each_with_object({}) do |(k,v),res|
        res[k] = if v.is_a?(Lazy)
                   v.value
                 elsif v.is_a?(Hash19)
                   v.to_h
                 else
                   v
                 end
      end.with_indifferent_access
    end

  end
end