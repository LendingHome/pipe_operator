require "rdoc/task"

task default: :ci

desc "scratchpad"
task :scratch do
  require "json"
  require "net/http"
  require_relative "lib/pipe_operator/autoload"

  puts "abc".pipe { reverse }        #=> "cba"
  puts "abc".pipe { reverse.upcase } #=> "CBA"

  # puts [9, 64].map(&Math.|.sqrt.to_i)
  # puts "single"
  # puts 256.pipe { Math.sqrt.to_i.to_s }.inspect
  # puts
  # puts "multiple"
  # puts [16, 256].map(&Math.|.sqrt.to_i.to_s).inspect

  # "https://api.github.com/repos/ruby/ruby".| do
  #   URI.parse
  #   Net::HTTP.get
  #   JSON.parse.fetch("stargazers_count")
  #   yield_self { |n| "Ruby has #{n} stars" }
  #   Kernel.puts
  # end
  # => Ruby has 15115 stars

  # p = ["256", "-16"].pipe do
  #   map(&:to_i)
  #   sort
  #   first
  #   abs
  #   Math.sqrt
  #   to_i
  # end
  #
  # puts p.inspect
end
task s: :scratch

desc "run tests, validate styleguide, and generate rdoc"
task :ci do
  %w[lint test doc].each do |task|
    command = "bundle exec rake #{task} --trace"
    system(command) || raise("#{task} failed")
    puts "\n"
  end
end

desc "validate styleguide"
task :lint do
  %w[fasterer rubocop].each do |task|
    command = "bundle exec #{task}"
    system(command) || exit(1)
  end
end
task l: :lint

desc "run tests"
task :test do
  exec "bundle exec rspec"
end
task t: :test


RDoc::Task.new :doc do |rdoc|
  rdoc.title = "pipe_operator"

  rdoc.main = "README.md"
  rdoc.rdoc_dir = "doc"

  rdoc.options << "--all"
  rdoc.options << "--hyperlink-all"
  rdoc.options << "--line-numbers"

  rdoc.rdoc_files.include(
    "LICENSE",
    "README.md",
    "lib/**/*.rb",
    "lib/*.rb"
  )
end
task d: :doc

desc "pry console"
task :console do
  require "base64"
  require "json"
  require "net/http"
  require "pry"
  require "pry-byebug"
  require_relative "lib/pipe_operator/autoload"

  PipeOperator.pry
end
task c: :console
