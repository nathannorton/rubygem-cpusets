
Gem::Specification.new do |s|
  s.name        = 'cpuset'
  s.version     = '0.0.11'
  s.date        = '2012-04-24'
  s.summary     = "cpuset"
  s.description = "A simple ruby interface to the cgroup/cpuset control group"
  s.authors     = ["Nathan Norton"]
  s.email       = 'nathan@nanoservices.com.au'
  s.files       = ["lib/cpuset.rb","lib/cpuset/cpuset_fs.rb"]
  s.homepage    = 'http://rubygems.org/gems/cpuset'
  s.has_rdoc    = false
  s.executables = ["cpuset"]
end
