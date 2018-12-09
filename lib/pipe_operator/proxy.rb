module PipeOperator
  class Proxy < ::Module
    def initialize(object, singleton)
      @object = object if singleton.singleton_class?
      @singleton = singleton
      super()
    end

    def define(method)
      if ::Proc == @object && method == :new
        return method
      elsif ::Symbol == @singleton && method == :to_proc
        return method
      elsif ::Module === @object
        namespace = @object.name.to_s.split("::").first
        return method if namespace == "PipeOperator"
      end

      define_method(method) do |*args, &block|
        if Pipe.open
          Pipe.new(self).__send__(method, *args, &block)
        else
          super(*args, &block)
        end
      end
    end

    def definitions
      instance_methods(false).sort
    end

    def inspect
      inspect =
        if @singleton.singleton_class?
          ::PipeOperator.inspect(@object)
        else
          "#<#{@singleton.name}>"
        end

      "#<#{self.class.name}:#{inspect}>"
    end

    def prepended(*)
      if is_a?(Proxy)
        methods = @singleton.instance_methods(false)
        methods.each { |method| define(method) }
      end

      super
    end

    def undefine(method)
      remove_method(method)
    rescue ::NameError # ignore
      method
    end
  end
end
