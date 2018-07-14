require 'faye'
require 'eventmachine'

endpoint = 'http://0.0.0.0:9292/faye'

EM.run do
  puts "Connecting to #{endpoint}"

  client = Faye::Client.new(endpoint)

  subscription = client.subscribe '/fortune' do |message|
    puts message
  end
end
