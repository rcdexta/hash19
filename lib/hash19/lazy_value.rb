module Hash19
  class LazyValue
    def initialize(callable)
      @block = callable
    end

    def value
      @block.call
    end
  end
end