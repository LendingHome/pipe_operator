# ![LendingHome](https://avatars0.githubusercontent.com/u/5448482?s=24&v=4) pipe_operator

> Elixir/Unix style pipe operations in Ruby - **PROOF OF CONCEPT**

```ruby
"https://api.github.com/repos/ruby/ruby".pipe do
  URI.parse
  Net::HTTP.get
  JSON.parse.fetch("stargazers_count")
  yield_self { |n| "Ruby has #{n} stars" }
  Kernel.puts
end
#=> Ruby has 15120 stars
```

```ruby
-9.pipe { abs; Math.sqrt; to_i } #=> 3

# Method chaining is supported:
-9.pipe { abs; Math.sqrt.to_i.to_s } #=> "3
```

```ruby
sqrt = Math.pipe.sqrt #=> #<PipeOperator::Closure:0x00007fc1172ed558@pipe_operator/closure.rb:18>
sqrt.call(9)          #=> 3.0
sqrt.call(64)         #=> 8.0

[9, 64].map(&Math.pipe.sqrt)           #=> [3.0, 8.0]
[9, 64].map(&Math.pipe.sqrt.to_i.to_s) #=> ["3", "8"]
```

## Why?

There's been some recent activity related to `Method` and `Proc` composition in Ruby:

* [#6284 - Add composition for procs](https://bugs.ruby-lang.org/issues/6284)
* [#13581 - Syntax sugar for method reference](https://bugs.ruby-lang.org/issues/13581)
* [#12125 - Shorthand operator for Object#method](https://bugs.ruby-lang.org/issues/12125)

This gem was created to **propose an alternative syntax** for this kind of behavior.

## Matz on Ruby

Source: [ruby-lang.org/en/about](https://www.ruby-lang.org/en/about)

Ruby is a language of careful **balance of both functional and imperative programming**.

Matz has often said that he is **trying to make Ruby natural, not simple**, in a way that mirrors life.
 
Building on this, he adds: Ruby is **simple in appearance, but is very complex inside**, just like our human body.

## Concept

The general idea is to **pass the result of one expression as an argument to another expression** - similar to [Unix pipelines](https://en.wikipedia.org/wiki/Pipeline_(Unix)):

```ruby
echo "testing" | sed "s/ing//" | rev
#=> tset
```

The [Elixir pipe operator documentation](https://elixirschool.com/en/lessons/basics/pipe-operator/) has some other examples but basically it allows expressions like:

```ruby
JSON.parse(Net::HTTP.get(URI.parse(url)))
```

To be **inverted** and rewritten as **left to right** or **top to bottom** which is more **natural to read** in English:

```ruby
# left to right
url.pipe { URI.parse; Net::HTTP.get; JSON.parse }

# or top to bottom for clarity
url.pipe do
  URI.parse
  Net::HTTP.get
  JSON.parse
end
```

The differences become a bit **clearer when other arguments are involved**:

```ruby
loans = Loan.preapproved.submitted(Date.current).where(broker: Current.user)
data = loans.map { |loan| LoanPresenter.new(loan).as_json }
json = JSON.pretty_generate(data, allow_nan: false)
```

Using pipes **removes the verbosity of maps and temporary variables**:

```ruby
json = Loan.pipe do
  preapproved
  submitted(Date.current)
  where(broker: Current.user)
  map(&LoanPresenter.new.as_json)
  JSON.pretty_generate(allow_nan: false)
end
```

While the ability to perform a job correctly and efficiently is certainly important - the **true beauty of a program lies in its clarity and conciseness**:

```ruby
"https://api.github.com/repos/ruby/ruby".pipe do
  URI.parse
  Net::HTTP.get
  JSON.parse.fetch("stargazers_count")
  yield_self { |n| "Ruby has #{n} stars" }
  Kernel.puts
end
#=> Ruby has 15115 stars
```

There's nothing really special here - it's just a **block of expressions like any other Ruby DSL** and pipe operations have been [around for decades](https://en.wikipedia.org/wiki/Pipeline_(Unix))!

```ruby
Ruby.is.so(elegant, &:expressive).that(you can) do
  pretty_much ANYTHING if it.compiles!
end
```

This concept of **pipe operations could be a great fit** like it has been for many other languages:

* [Caml composition operators](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Pervasives.html#1_Compositionoperators)
* [Closure threading macros](https://clojure.org/guides/threading_macros)
* [Elixir pipe operator](https://elixirschool.com/en/lessons/basics/pipe-operator/)
* [Elm operators](https://elm-lang.org/docs/syntax#operators)
* [F# function composition and pipelining](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/functions/index#function-composition-and-pipelining)
* [Hack pipe operator](https://docs.hhvm.com/hack/operators/pipe-operator)
* [Haskell pipes](http://hackage.haskell.org/package/pipes-4.3.9/docs/Pipes-Tutorial.html)
* [JavaScript pipeline operator proposals](https://github.com/tc39/proposal-pipeline-operator/wiki)
* [LiveScript piping](http://livescript.net/#piping)
* [Unix pipelines](https://en.wikipedia.org/wiki/Pipeline_(Unix))

## Usage

**WARNING - EXPERIMENTAL PROOF OF CONCEPT**

This has only been **tested in isolation with RSpec and Ruby 2.5.3**!

```ruby
# First `gem install pipe_operator`
require "pipe_operator"
```

## Implementation

The [PipeOperator](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator.rb) module has a method named `__pipe__` which is aliased as `pipe` for convenience:

```ruby
module PipeOperator
  def __pipe__(*args, &block)
    Pipe.new(self, *args, &block)
  end
end

BasicObject.send(:include, PipeOperator)
Kernel.alias_method(:pipe, :__pipe__)
```

When no arguments are passed to `__pipe__` then a [PipeOperator::Pipe](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb) object is returned:

```ruby
Math.pipe #=> #<PipeOperator::Pipe:Math>
```

Any methods invoked on this object returns a [PipeOperator::Closure](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/closure.rb) which **calls the method on the object later**:

```ruby
sqrt = Math.pipe.sqrt       #=> #<PipeOperator::Closure:0x00007fc1172ed558@pipe_operator/closure.rb:18>
sqrt.call(16)               #=> 4.0

missing = Math.pipe.missing #=> #<PipeOperator::Closure:0x00007fc11726f0e0@pipe_operator/closure.rb:18>
missing.call                #=> NoMethodError: undefined method 'missing' for Math:Module

Math.method(:missing)       #=> NameError: undefined method 'missing' for class '#<Class:Math>'
```

When `__pipe__` is called **with arguments but without a block** then it behaves similar to `__send__`:

```ruby
sqrt = Math.pipe(:sqrt) #=> #<PipeOperator::Closure:0x00007fe52e0cdf80@pipe_operator/closure.rb:18>
sqrt.call(16)           #=> 4.0

sqrt = Math.pipe(:sqrt, 16) #=> #<PipeOperator::Closure:0x00007fe52fa18fd0@pipe_operator/closure.rb:18>
sqrt.call                   #=> 4.0
sqrt.call(16)               #=> ArgumentError: wrong number of arguments (given 2, expected 1)
```

These [PipeOperator::Closure](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/closure.rb) objects can be [bound as block arguments](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/proxy.rb#L10-L13) just like any other [Proc](https://ruby-doc.org/core-2.5.3/Proc.html):

```ruby
[16, 256].map(&Math.pipe.sqrt) #=> [4.0, 16.0]
```

Simple **closure composition is supported** via [method chaining](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/closure.rb#L56):

```ruby
[16, 256].map(&Math.pipe.sqrt.to_i.to_s) #=> ["4", "16"]
```

The **block** form of `__pipe__` behaves **similar to instance_exec** but can also [call methods on other objects](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb#L81):

```ruby
"abc".pipe { reverse }        #=> "cba"
"abc".pipe { reverse.upcase } #=> "CBA"

"abc".pipe { Marshal.dump }                  #=> "\x04\bI\"\babc\x06:\x06ET"
"abc".pipe { Marshal.dump; Base64.encode64 } #=> "BAhJIghhYmMGOgZFVA==\n"
```

Outside the context of a `__pipe__` block things behave like normal:

```ruby
Math.sqrt     #=> ArgumentError: wrong number of arguments (given 0, expected 1)
Math.sqrt(16) #=> 4.0
```

But within a `__pipe__` block the `Math.sqrt` expression returns a [PipeOperator::Closure](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/closure.rb) instead:

```ruby
16.pipe { Math.sqrt }     #=> 4.0
16.pipe { Math.sqrt(16) } #=> ArgumentError: wrong number of arguments (given 2, expected 1)
```

The **piped object is passed as the first argument by default** but can be customized by specifying `self`:

```ruby
class String
  def self.join(*args, with: "")
    args.map(&:to_s).join(with)
  end
end

"test".pipe { String.join("123", with: "-") }       #=> "test-123"

"test".pipe { String.join("123", self, with: "-") } #=> "123-test"
```

Instance methods like `reverse` below [do not receive the piped object](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb#L79) as [an argument](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/closure.rb#L47) since it's available as `self`:

```ruby
Base64.encode64(Marshal.dump("abc").reverse)          #=> "VEUGOgZjYmEIIkkIBA==\n"

"abc".pipe { Marshal.dump; reverse; Base64.encode64 } #=> "VEUGOgZjYmEIIkkIBA==\n"

"abc".pipe { Marshal.dump.reverse; Base64.encode64 }  #=> "VEUGOgZjYmEIIkkIBA==\n"
```

Pipes also support **multi-line blocks for clarity**:

```ruby
"abc".pipe do
  Marshal.dump.reverse
  Base64.encode64
end
```

The closures created by these **pipe expressions are evaluated via reduce**:

```ruby
pipeline = [
  -> object { Marshal.dump(object) },
  -> object { object.reverse },
  -> object { Base64.encode64(object) },
]

pipeline.reduce("abc") do |object, pipe|
  pipe.call(object)
end
```

[Intercepting methods](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/proxy.rb#L19-L25) within pipes requires [prepending](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb#L38) a [PipeOperator::Proxy](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/proxy.rb) module infront of `::Object` and all [nested constants](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/proxy_resolver.rb#L46):

```ruby
define_method(method) do |*args, &block|
  if Pipe.open
    Pipe.new(self).__send__(method, *args, &block)
  else
    super(*args, &block)
  end
end
```

These **proxy modules are prepended everywhere**!

It's certainly something that **could be way more efficient as a core part of Ruby**.

Maybe somewhere **lower level where methods are dispatched**? Possibly somewhere in this [vm_eval.c switch](https://github.com/ruby/ruby/blob/trunk/vm_eval.c#L111)?

```c
again:
  switch (cc->me->def->type) {
    case VM_METHOD_TYPE_ISEQ
    case VM_METHOD_TYPE_NOTIMPLEMENTED
    case VM_METHOD_TYPE_CFUNC
    case VM_METHOD_TYPE_ATTRSET
    case VM_METHOD_TYPE_IVAR
    case VM_METHOD_TYPE_BMETHOD
    case VM_METHOD_TYPE_ZSUPER
    case VM_METHOD_TYPE_REFINED
    case VM_METHOD_TYPE_ALIAS
    case VM_METHOD_TYPE_MISSING
    case VM_METHOD_TYPE_OPTIMIZED
    case OPTIMIZED_METHOD_TYPE_SEND
    case OPTIMIZED_METHOD_TYPE_CALL
    case VM_METHOD_TYPE_UNDEF
  }
```

Then we'd **only need Ruby C API ports** for [PipeOperator::Pipe](https://github.com/LendingHome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb) and [PipeOperator::Closure](https://github.com/LendingHome/pipe_operator/blob/master/lib/pipe_operator/closure.rb)!

All other objects in this proof of concept are related to **method interception** and would no longer be necessary.

## Bugs

This test case doesn't work yet - seems like the [object is not proxied](https://github.com/lendinghome/pipe_operator/blob/master/lib/pipe_operator/pipe.rb#L39) for some reason:

```ruby
class Markdown
  def format(string)
    string.upcase
  end
end

"test".pipe(Markdown.new, &:format) # expected "TEST"
#=> ArgumentError: wrong number of arguments (given 0, expected 1)
```

## Caveats

* `PIPE_OPERATOR_AUTOLOAD`
    * Constants flagged for autoload are NOT proxied by default (for performance)
    * Set `ENV["PIPE_OPERATOR_AUTOLOAD"] = 1` to enable this behavior
* `PIPE_OPERATOR_FROZEN`
    * Objects flagged as frozen are NOT proxied by default
    * Set `ENV["PIPE_OPERATOR_FROZEN"] = 1` to enable this behavior (via [Fiddle](http://ruby-doc.org/stdlib-2.5.3/libdoc/fiddle/rdoc/Fiddle.html))
* `PIPE_OPERATOR_REBIND`
    * `Object` and its recursively nested `constants` are only proxied ONCE by default (for performance)
    * Constants defined after `__pipe__` is called for the first time are NOT proxied
    * Set `ENV["PIPE_OPERATOR_REBIND"] = 1` to enable this behavior
* `PIPE_OPERATOR_RESERVED`
    * The following methods are reserved on `PipeOperator::Closure` objects:
        * `==`
        * `[]`
        * `__chain__`
        * `__send__`
        * `__shift__`
        * `call`
        * `class`
        * `kind_of?`
    * The following methods are reserved on `PipeOperator::Pipe` objects:
        * `!`
        * `!=`
        * `==`
        * `__call__`
        * `__id__`
        * `__pop__`
        * `__push__`
        * `__send__`
        * `instance_exec`
        * `method_missing`
    * These methods can be piped via `send` as a workaround:
        * `9.pipe { Math.sqrt.to_s.send(:[], 0) }`
        * `example.pipe { send(:__call__, 1, 2, 3) }`
        * `example.pipe { send(:instance_exec) { } }`

## Testing

```bash
bundle exec rspec
```

## Inspiration

* https://github.com/hopsoft/pipe_envy
* https://github.com/akitaonrails/chainable_methods
* https://github.com/kek/pipelining
* https://github.com/k-motoyan/shelike-pipe
* https://github.com/nwtgck/ruby_pipe_chain
* https://github.com/teamsnap/pipe-ruby
* https://github.com/danielpclark/elixirize
* https://github.com/tiagopog/piped_ruby
* https://github.com/jicksta/methodphitamine
* https://github.com/jicksta/superators
* https://github.com/baweaver/xf

## Contributing

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so we don't break it in a future version unintentionally.
* Commit, do not mess with the version or history.
* Open a pull request. Bonus points for topic branches.

## Authors

* [Sean Huber](https://github.com/shuber)

## License

[MIT](https://github.com/lendinghome/pipe_operator/blob/master/LICENSE) - Copyright © 2018 LendingHome
