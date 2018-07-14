require 'pp'
require 'serialport'
require 'pry'
require 'faye'
require 'eventmachine'
require 'net/http'

class FayeClient
  def self.client
    @client ||= begin
      Thread.new { EM.run } unless EM.reactor_running?
      Thread.pass until EM.reactor_running?
      Faye::Client.new('http://0.0.0.0:9292/faye')
    end
  end
end

class TTy
 def initialize
   # defaults params for arduino serial
   baud_rate = 9600
   data_bits = 8
   stop_bits = 1
   parity = SerialPort::NONE

   # serial port
   @sp = nil
   @port = nil
 end

 def open(port)
   @sp = SerialPort.new(port, @baud_rate, @data_bits, @stop_bits, @parity)
 end

 def shutdown(reason)
   return if @sp.nil?
   return if reason == :int

   printf("\nshutting down serial (%s)\n", reason)

   # you may write something before closing tty
   @sp.write(0x00)
   @sp.flush
   printf("done\n")
 end

 def read
   @sp.flush
   message = @sp.gets
   puts message
   match = /\X:(.*)Y:(.*)Z:(.*)/m.match(message)
   if match && match.length == 4
     x = match[1].to_f
     y = match[2].to_f
     z = match[3].to_f
     return { x: x, y: y, z: z }
   end
 end

 def write(c)
   @sp.putc(c)
   @sp.flush
   printf("# W : 0x%02x\n", c.ord)
 end

 def flush
   @sp.flush
 end
end

tty = TTy.new
tty.open('/dev/ttyACM0')

at_exit     { tty.shutdown :exit }
trap('INT') { tty.shutdown :int; exit }

@counter = 0
@blocker_counter = 0
@blocker = false

# just read forever
loop do
 @counter = 0 if @counter > 8
 @counter += 1

 if @counter == 1
   @min_x = @min_y = @min_z = 1000
   @max_x = @max_y = @max_z = -1000
 end

 if @blocker_counter >= 4
   @thread.kill && @thread = nil if @thread
   @blocker = false
   @thread = Thread.new do
     Net::HTTP.get(URI.parse('http://localhost:8787/put/animation.index/2'))
     Net::HTTP.get(URI.parse("http://localhost:8787/put/animation.animation.fps/#{rand(10..30)}"))
    end
   @blocker_counter = 0
 end

 if @counter == 8
   @blocker_counter += 1 if @blocker
   x_var = @max_x - @min_x
   y_var = @max_y - @min_y
   z_var = @max_z - @min_z
   puts x_var
   puts y_var
   puts z_var
   puts "blocker: #{@blocker}, blocker_counter: #{@blocker_counter}"
   if x_var > 8 || y_var > 8
     puts 'Bell detected'
     @thread.kill && @thread = nil if @thread
     unless @blocker
       puts 'Bell Rang'
       FayeClient.client.publish('/fortune', {text: "This is your fortune." } )
       @thread = Thread.new do
         Net::HTTP.get(URI.parse('http://localhost:8787/put/animation.index/3'))
         Net::HTTP.get(URI.parse('http://localhost:8787/put/animation.animation.fps/3'))
       end
       @blocker = true
    end
  end
end

 hash = tty.read
 if hash
   @min_x = hash[:x] if hash[:x] < @min_x
   @max_x = hash[:x] if hash[:x] > @max_x
   @min_y = hash[:y] if hash[:y] < @min_y
   @max_y = hash[:y] if hash[:y] > @max_y
   @min_z = hash[:z] if hash[:z] < @min_z
   @max_z = hash[:z] if hash[:z] > @max_z
 end
 sleep(0.3)
end

sleep 500
tty.shutdown
