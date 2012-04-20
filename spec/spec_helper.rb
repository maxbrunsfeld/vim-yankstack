require "vimbot"

PLUGIN_ROOT = File.expand_path("../..", __FILE__)

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
end

