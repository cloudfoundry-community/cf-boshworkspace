directories %w(templates deployments spec)

guard :rspec, cmd: "bundle exec rspec --fail-fast" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_files)
  watch(%r{.yml}) { rspec.spec_dir }
end
