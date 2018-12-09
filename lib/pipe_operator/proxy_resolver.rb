module PipeOperator
  class ProxyResolver
    AUTOLOAD = ENV["PIPE_OPERATOR_AUTOLOAD"] == "1"
    FROZEN = ENV["PIPE_OPERATOR_FROZEN"] == "1"
    REBIND = ENV["PIPE_OPERATOR_REBIND"] == "1"

    def initialize(object, resolved = ::Set.new)
      @object = object
      @resolved = resolved
      @singleton = ::PipeOperator.singleton(object)
    end

    def proxy
      proxy = find_existing_proxy
      return proxy if proxy && !REBIND
      proxy ||= create_proxy
      rebind_nested_constants
      proxy
    end

    private

    def find_existing_proxy
      @singleton.ancestors.each do |existing|
        break if @singleton == existing
        return existing if Proxy === existing
      end
    end

    def create_proxy
      Proxy.new(@object, @singleton).tap do |proxy|
        @resolved.add(proxy)

        if !@singleton.frozen?
          @singleton.prepend(Observer).prepend(proxy)
        elsif FROZEN
          id = @singleton.__id__ * 2
          unfreeze = ~(1 << 3)
          ::Fiddle::Pointer.new(id)[1] &= unfreeze
          @singleton.prepend(Observer).prepend(proxy)
          @singleton.freeze
        end
      end
    end

    def rebind_nested_constants
      context = ::Module === @object ? @object : @singleton

      context.constants.map do |constant|
        next unless context.const_defined?(constant, AUTOLOAD)

        constant = silence_deprecations do
          context.const_get(constant, false) rescue next
        end

        next if constant.eql?(@object) # recursion
        next unless @resolved.add?(constant)

        self.class.new(constant, @resolved).proxy
      end
    end

    def silence_deprecations
      stderr = $stderr
      $stderr = ::StringIO.new
      yield
    ensure
      $stderr = stderr
    end
  end
end
