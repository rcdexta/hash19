module Hash19
  module Resolvers

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
        if association.present?
          klass = resolve_class(class_name.singularize)
          @hash19[opts[:alias] || name] = if type == :one
                                            klass.send(:new, association).to_h(lazy: true)
                                          elsif type == :many
                                            association.map { |hash| klass.send(:new, hash).to_h(lazy: true) }
                                          end
        else
          # raise "Key:<#{name}> is not present in #{self.class.name}. Possible specify a trigger" unless
          @hash19[opts[:alias] || name] = LazyValue.new(-> { opts[:trigger].call(@hash19.delete(opts[:using])) }) if opts[:trigger]
        end
      end
    end

    def resolve_aliases
      self.class.aliases.each do |key, as|
        @hash19[as] = @hash19.delete(key) if @hash19.has_key?(key)
      end
    end

    def resolve_injections(hash)
      together do
        self.class.injections.each do |opts|
          async do
            entries = JsonPath.new(opts[:at]).on(hash).flatten
            ids = entries.map { |el| el[opts[:using]] }
            to_inject = opts[:trigger].call(ids).map(&:with_indifferent_access)
            key = opts[:as] || opts[:using].to_s.gsub(/_id$|Id$/, '')
            entries.each do |entry|
              id = entry.delete(opts[:using])
              target = to_inject.find { |el| el[opts[:reference] || opts[:using]] == id }
              entry[key] = target
            end
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

  end
end