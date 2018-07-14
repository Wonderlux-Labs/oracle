require 'pp'
require 'serialport'
require 'pry'

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
    message = @sp.read
    puts message
    match = /\X:\((.*)\)Y:\((.*)\)Z:\((.*)\)/x.match(message)
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

# serial port should be connected to /dev/ttyUSB*
# ports = Dir.glob('/dev/ttyUSB*')
# if ports.size != 1
#   printf('did not found right /dev/ttyUSB* serial')
#   exit(1)
# end

tty = TTy.new
tty.open('/dev/ttyACM0')

at_exit     { tty.shutdown :exit }
trap('INT') { tty.shutdown :int; exit }

@counter = 0

# just read forever
loop do
  @counter = 0 if @counter > 10
  @counter += 1

  if @counter == 1
    @min_x = @min_y = @min_z = 1000
    @max_x = @max_y = @max_z = -1000
  end

  if @counter == 10
    x_var = @max_x - @min_x
    y_var = @max_y - @min_y
    z_var = @max_z - @min_z
    puts x_var
    puts y_var
    puts z_var
    puts 'BELL RANG' if x_var > 4 || y_var > 4 || z_var > 4
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
  sleep(0.25)
end

sleep 500
tty.shutdown
