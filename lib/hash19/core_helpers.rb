module Hash19
  module CoreHelpers

    attr_accessor :keys
    attr_accessor :aliases
    attr_accessor :one_assocs
    attr_accessor :many_assocs
    attr_accessor :injections
    attr_accessor :contains_klass

    def attributes(*list)
      add_attributes(*list)
    end

    def attribute(name, opts = {})
      add_attributes(opts[:key] || name)
      @aliases ||= {}
      @aliases[opts[:key]] = name if opts.has_key?(:key)
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

    def contains(class_name)
      @contains_klass = class_name
    end

    private

    def add_attributes(*list)
      @keys ||= []
      @keys += list
    end
  end
end