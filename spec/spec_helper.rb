$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'money'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
end

shared_context 'actual subject', subject: :present?.to_proc do
  subject { send(example.metadata[:subject]) }
end

shared_context 'method setup from metadata', method: :present?.to_proc do
  let(:recipient) { subject }
  let(:method) { example.metadata[:method] }
  let(:args) { [] }
  let(:action) { lambda { recipient.send(*[method, *args]) } }
end
