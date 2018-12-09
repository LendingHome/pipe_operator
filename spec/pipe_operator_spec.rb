RSpec.describe PipeOperator do
  using PipeOperator

  describe ".gem" do
    it "returns a Gem::Specification" do
      gem = PipeOperator.gem
      expect(gem).to be_a(::Gem::Specification)
      expect(gem.name).to eq("pipe_operator")
      expect(gem.version).to be_a(::Gem::Version)
    end
  end

  describe ".root" do
    it "returns a Pathname to gem root" do
      expected = ::Pathname.new(__dir__).join("..")
      expect(PipeOperator.root).to match(expected)
    end
  end

  describe ".version" do
    it "returns a version string" do
      expected = /^\d+\.\d+\.\d+$/
      expect(PipeOperator.version).to match(expected)
    end
  end

  describe "#pipe" do
    it "doesn't break existing behavior" do
      actual = Math.sqrt(9)
      expect(actual).to eq(3)
    end

    it "returns a pipe object that responds to anything" do
      actual = Math.|
      expect(actual).to be_a(PipeOperator::Pipe)
      expect { actual.anything }.not_to raise_error
    end

    it "returns a callable proc" do
      pipe = Math.|
      sqrt = pipe.sqrt
      expect(sqrt).to be_a(::Proc)
      expect(sqrt).to be_a(PipeOperator::Closure)

      actual = sqrt[9]
      expect(actual).to eq(3)

      actual = sqrt.(9)
      expect(actual).to eq(3)

      actual = sqrt.call(9)
      expect(actual).to eq(3)
    end

    it "casts to &block" do
      actual = [9].map(&Math.|.sqrt)
      expect(actual).to eq([3])

      actual = [3].map(&2.pipe.send(:*))
      expect(actual).to eq([6])
    end

    it "curries arguments and blocks" do
      actual = "testing".|.sub("test").("TEST")
      expect(actual).to eq("TESTing")

      actual = ["testing"].pipe.map(&:upcase).call
      expect(actual).to eq(["TESTING"])

      actual = ["testing"].pipe.map(&:upcase).call(&:reverse)
      expect(actual).to eq(["gnitset"])

      actual = 2.pipe{Math.atan2(3)}
      expect(actual).to eq(0.982793723247329)

      actual = -2.pipe{abs | Math.atan2(self, 3) | to_s}
      expect(actual).to eq("0.5880026035475675")
    end

    it "behaves like __send__ with args and no block" do
      sqrt = Math | :sqrt
      actual = sqrt.call(16)
      expect(actual).to eq(4.0)

      sqrt = Math.pipe(:sqrt, 16)
      actual = sqrt.call
      expect(actual).to eq(4.0)

      expect { sqrt.call(16) }.to raise_error(::ArgumentError)
    end

    it "behaves like instance_exec with a block" do
      actual = "abc".pipe { reverse }
      expect(actual).to eq("cba")

      actual = "abc".pipe { reverse.upcase }
      expect(actual).to eq("CBA")

      actual = "abc".pipe { reverse | upcase }
      expect(actual).to eq("CBA")
    end

    it "supports calling objects on other methods" do
      actual = "abc".pipe { Marshal.dump | Base64.encode64 }
      expect(actual).to eq("BAhJIghhYmMGOgZFVA==\n")
    end

    it "supports pipe and stream expressions" do
      actual = "-9".|{to_i}
      expect(actual).to eq(-9)

      actual = "-9".|{to_i; abs}
      expect(actual).to eq(9)

      actual = "-9".|{to_i; abs; Math.sqrt}
      expect(actual).to eq(3)

      actual = "-9".pipe { to_i | abs | Math.sqrt }
      expect(actual).to eq(3)

      actual = "-9".|{to_i; abs; Math.sqrt; to_i; send(:*, 2)}
      expect(actual).to eq(6)

      actual = "-16".|{
        to_i
        abs
        Math.sqrt
        Math.sqrt
      }
      expect(actual).to eq(2)

      actual = ["-16", "256"].pipe do
        lazy # streams
        map { |n| n.to_i.abs }
        map { |n| n * 2 }
      end
      expect(actual).to be_an(Enumerator::Lazy)
      expect(actual.to_a).to eq([32, 512])
    end

    it "resolves recursive pipes" do
      actual = ["-16", "256"].pipe do
        lazy
        map { |n| n.to_i.abs }
        map { |n| n * 2 }
        map(&Math.sqrt)
        map(&Math.sqrt)
        reduce(&:+)
        Math.sqrt
        ceil
      end
      expect(actual).to eq(3)
    end

    it "resolves pipe chain" do
      pipe = Math.|.sqrt.to_i.to_s
      actual = pipe.call(256)
      expect(actual).to eq("16")

      actual = 64.pipe{Math.sqrt.to_i.to_s}
      expect(actual).to eq("8")

      actual = [64].map(&Math.|.sqrt.to_i.to_s)
      expect(actual).to eq(["8"])

      actual = [64, 256].map(&Math.|.sqrt.to_i.to_s)
      expect(actual).to eq(["8", "16"])
    end

    it "proxies pipe arguments", :pending do
      class Markdown
        def format(string)
          string.upcase
        end
      end

      actual = Markdown.new.|.format.call("test")
      expect(actual).to eq("TEST")

      actual = "test".pipe(Markdown.new, &:format)
      expect(actual).to eq("TEST")
    end

    it "observes method changes" do
      methods = Math.methods(false).sort
      expect(methods).not_to be_empty

      proxy = PipeOperator::ProxyResolver.new(Math).proxy
      expect(proxy.definitions).to eq(methods)
      expect(proxy.definitions).not_to include(:test)

      def Math.test; end
      expect(proxy.definitions).to include(:test)

      Math.singleton_class.remove_method(:test)
      expect(proxy.definitions).not_to include(:test)

      expect{ proxy.undefine(:invalid) }.not_to raise_error
    end

    it "varies Pipe#inspect based on the object" do
      basic = ::BasicObject.new
      def basic.hash; 0 end

      expected = {
        ::BasicObject => "#<PipeOperator::Pipe:BasicObject>",
        ::Class       => "#<PipeOperator::Pipe:Class>",
        ::Class.new   => /#<PipeOperator::Pipe:#<Class:.+>>/,
        ::Math        => "#<PipeOperator::Pipe:Math>",
        123           => "#<PipeOperator::Pipe:123>",
        true          => "#<PipeOperator::Pipe:true>",
        basic         => /#<PipeOperator::Pipe:#<BasicObject:.+>>/,
      }

      expected.each do |object, inspect|
        pipe = object.__pipe__
        matcher = Regexp === inspect ? match(inspect) : eq(inspect)
        expect(pipe.inspect).to matcher
      end
    end

    it "varies ProxyResolver#inspect based on the object" do
      basic = ::BasicObject.new
      def basic.hash; 0 end

      expected = {
        ::BasicObject => "#<PipeOperator::Proxy:BasicObject>",
        ::Class       => "#<PipeOperator::Proxy:Class>",
        ::Class.new   => /#<PipeOperator::Proxy:#<Class:.+>>/,
        ::Math        => "#<PipeOperator::Proxy:Math>",
        123           => "#<PipeOperator::Proxy:#<Integer>>",
        true          => "#<PipeOperator::Proxy:#<TrueClass>>",
        basic         => /#<PipeOperator::Proxy:#<BasicObject:.+>>/,
      }

      expected.each do |object, inspect|
        proxy = PipeOperator::ProxyResolver.new(object).proxy
        matcher = Regexp === inspect ? match(inspect) : eq(inspect)
        expect(proxy.inspect).to matcher
      end
    end
  end
end
