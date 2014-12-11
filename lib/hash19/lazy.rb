module Hash19
  class Lazy
    def initialize(callable)
      @block = callable
    end

    def value
      @block.call
    end
  end
end