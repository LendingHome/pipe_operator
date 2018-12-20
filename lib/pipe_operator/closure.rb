module PipeOperator
  class Closure < ::Proc
    RESERVED = %i[
      ==
      []
      __send__
      call
      class
      kind_of?
    ].freeze

    (::Proc.instance_methods - RESERVED).each(&method(:private))

    def self.curry(curry, search, args)
      index = curry.index(search)
      prefix = index ? curry[0...index] : curry
      suffix = index ? curry[index - 1..-1] : []

      (prefix + args + suffix).map do |object|
        self === object ? object.call : object
      end
    end

    def self.new(pipe = nil, method = nil, *curry, &block)
      return super(&block) unless pipe && method

      search = Pipe.open || pipe

      closure = super() do |*args, &code|
        code ||= block
        curried = curry(curry, search, args)
        value = pipe.__call__.__send__(method, *curried, &code)
        closure.__chain__(value)
      end
    end

    def initialize(*) # :nodoc:
      @__chain__ ||= []
      super
    end

    def __chain__(*args)
      return @__chain__ if args.empty?

      @__chain__.reduce(args[0]) do |object, chain|
        method, args, block = chain
        object.__send__(method, *args, &block)
      end
    end

    def __shift__
      closure = self.class.new do |*args, &block|
        args.shift
        value = call(*args, &block)
        closure.__chain__(value)
      end
    end

    private

    def method_missing(method, *args, &block)
      __chain__ << [method, args, block]
      self
    end
  end
end
