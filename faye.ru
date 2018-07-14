require 'faye'

Faye::WebSocket.load_adapter('thin')
Faye.logger = Logger.new(STDOUT)
faye = Faye::RackAdapter.new(mount: '/faye', :timeout => 5)
run faye
