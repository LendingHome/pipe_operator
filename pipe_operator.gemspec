Gem::Specification.new do |s|
  s.author                = "LendingHome"
  s.email                 = "engineering@lendinghome.com"
  s.extra_rdoc_files      = ["LICENSE"]
  s.files                 = `git ls-files 2>/dev/null`.split("\n")
  s.homepage              = "https://github.com/lendinghome/pipe_operator"
  s.license               = "MIT"
  s.name                  = "pipe_operator"
  s.required_ruby_version = ">= 2.0.0"
  s.summary               = "Elixir/Unix style pipe operations in Ruby"
  s.test_files            = `git ls-files -- spec/* 2>/dev/null`.split("\n")
  s.version               = "0.0.2"

  s.rdoc_options = %w[
    --all
    --charset=UTF-8
    --hyperlink-all
    --inline-source
    --line-numbers
    --main README.md
  ]
end
