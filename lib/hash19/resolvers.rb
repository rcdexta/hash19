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
                                            klass.send(:new, association).to_h(true)
                                          elsif type == :many
                                            association.map { |hash| klass.send(:new, hash).to_h(true) }
                                          end
        else
          unless opts[:trigger]
            # puts "warning: Association:<#{name}> is not present in #{self.class.name}. Probably a trigger is missing!" 
            next
          end
          puts "warning: Key:<#{opts[:using]}> not present in #{self.class.name}. Cannot map association:<#{name}>" unless @hash19.has_key? opts[:using]
          if opts[:trigger] and @hash19.has_key? opts[:using]
            @hash19[opts[:alias] || name] = LazyValue.new(-> { opts[:trigger].call(@hash19.delete(opts[:using])) })
          end
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
        async_injections.each do |opts|
          async { call_and_inject(opts, hash) }
        end
      end
      synchronous_injections.each { |opts| call_and_inject(opts, hash) }
    end

    def resolve_class(assoc_name)
      full_class_name = self.class.name
      new_class = full_class_name.gsub(full_class_name.demodulize, assoc_name)
      new_class.split('::').inject(Object) do |mod, class_name|
        begin
          mod.const_get(class_name)
        rescue NameError
          raise("Class:<#{new_class}> not defined! Unable to resolve association:<#{assoc_name.downcase}>")
        end
      end
    end

    private

    def async_injections
      self.class.injections.select { |e| e[:async].nil? }
    end

    def synchronous_injections
      self.class.injections.select { |e| e[:async] == false }
    end

    def call_and_inject(opts, hash)
      entries = JsonPath.new(opts[:at]).on(hash).flatten
      ids = entries.map { |el| el[opts[:using]] }.compact
      return unless ids.present?
      to_inject = opts[:trigger].call(ids).map(&:with_indifferent_access)
      key = opts[:as] || opts[:using].to_s.gsub(/_id$|Id$/, '')
      entries.each do |entry|
        id = entry[opts[:using]]
        next unless id.present?
        target = to_inject.find { |el| el[opts[:reference] || opts[:using]] == id }
        if target
          entry.delete(opts[:using])
          entry[key] = target
        end
      end
    end

  end
end