module PipeOperator
  class Pipe < ::BasicObject
    undef :equal?
    undef :instance_eval
    undef :singleton_method_added
    undef :singleton_method_removed
    undef :singleton_method_undefined

    def self.new(object, *args)
      if block_given?
        super.__call__
      elsif args.none? || Closure === args[0]
        super
      else
        super(object).__send__(*args)
      end
    end

    def self.open(pipe = nil)
      @pipeline ||= []
      @pipeline << pipe if pipe
      block_given? ? yield : @pipeline.last
    ensure
      @pipeline.pop if pipe
    end

    def initialize(object, *args, &block)
      @args = args
      @block = block
      @object = object
      @pipeline = []
    end

    def __call__
      if defined?(@pipe)
        return @pipe
      elsif @block
        ProxyResolver.new(::Object).proxy
        @args.each { |arg| ProxyResolver.new(arg).proxy }
        Pipe.open(self) { instance_exec(*@args, &@block) }
      end

      @pipe = @object
      @pipeline.each { |closure| @pipe = closure.call(@pipe) }
      @pipe
    end

    def inspect
      return method_missing(__method__) if Pipe.open
      inspect = ::PipeOperator.inspect(@object)
      "#<#{Pipe.name}:#{inspect}>"
    end

    protected

    def __pop__(pipe)
      index = @pipeline.rindex(pipe)
      @pipeline.delete_at(index) if index
    end

    def __push__(pipe)
      @pipeline << pipe
      pipe
    end

    private

    def method_missing(method, *curry, &block)
      closure = Closure.new(self, method, *curry, &block)

      pipe = Pipe.open
      pipe && [*curry, block].each { |o| pipe.__pop__(o) }

      if pipe == self
        __push__(closure.__shift__)
      elsif pipe
        pipe.__push__(closure)
      else
        closure
      end
    end
  end
end
