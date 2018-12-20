require "fiddle"
require "forwardable"
require "pathname"
require "set"

require_relative "pipe_operator/closure"
require_relative "pipe_operator/observer"
require_relative "pipe_operator/pipe"
require_relative "pipe_operator/proxy"
require_relative "pipe_operator/proxy_resolver"

module PipeOperator
  def __pipe__(*args, &block)
    Pipe.new(self, *args, &block)
  end

  class << self
    def gem
      @gem ||= ::Gem::Specification.load("#{root}/pipe_operator.gemspec")
    end

    def inspect(object)
      object.inspect
    rescue ::NoMethodError
      singleton = singleton(object)
      name = singleton.name || singleton.superclass.name
      id = "0x0000%x" % (object.__id__ << 1)
      "#<#{name}:#{id}>"
    end

    def root
      @root ||= ::Pathname.new(__dir__).join("..")
    end

    def singleton(object)
      (class << object; self end)
    rescue ::TypeError
      object.class
    end

    def version
      @version ||= gem.version.to_s
    end
  end
end

BasicObject.send(:include, PipeOperator)
Kernel.alias_method(:pipe, :__pipe__)
