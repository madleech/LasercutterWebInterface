Serial = require 'serialport'
{EventEmitter} = require 'events'
debug = require('debug')('webcut:serial')

class SerialPort extends EventEmitter
	# list available serial ports
	@ports: (cb) ->
		Serial.list (err, ports) ->
			cb ports
	
	# set up serial port
	constructor: (port, speed = 115200) ->
		@id = Math.floor(Math.random() * 1000)
		@serial = new Serial port,
			baudrate: speed
			lock: false
			parser: Serial.parsers.readline "\n"
		
		@serial.on 'open', =>
			debug "port open #{@id}"
			@emit 'connected'
	
		@serial.on 'data', (data) =>
			debug "rx: #{data} #{@id}"
			@emit 'data', "#{data}"
		
		@serial.on 'error', (err) =>
			debug "error: #{err}"
			@emit 'error', err
	
	write: (data, cb) ->
		debug "tx: #{data}"
		@serial.write data, (-> @once 'data', cb if cb)
	
	close: (cb) ->
		debug "closing serial port #{@id}"
		@serial.removeAllListeners()
		@serial.close (err) ->
			debug err


module.exports = SerialPort
