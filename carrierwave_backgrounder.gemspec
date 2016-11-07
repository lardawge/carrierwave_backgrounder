# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "backgrounder/version"

Gem::Specification.new do |s|
  s.name        = "carrierwave_backgrounder"
  s.version     = CarrierWave::Backgrounder::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Larry Sprock"]
  s.email       = ["larry@lucidbleu.com"]
  s.homepage    = "https://github.com/lardawge/carrierwave_backgrounder"
  s.licenses    = ["MIT"]
  s.summary     = %q{Offload CarrierWave's image processing and storage to a background process using Delayed Job, Resque, Sidekiq, Qu, Queue Classic or Girl Friday}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "carrierwave", [">= 0.5", "< 2.0"]

  s.add_development_dependency "rspec", ["~> 3.5.0"]
  s.add_development_dependency "rake"
end
