module PipeOperator
  module Observer
    def singleton_method_added(method)
      ProxyResolver.new(self).proxy.define(method)
      super
    end

    def singleton_method_removed(method)
      ProxyResolver.new(self).proxy.undefine(method)
      super
    end
  end
end
