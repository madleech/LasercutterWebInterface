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
		@serial = new Serial port,
			baudrate: speed
			lock: false
			parser: Serial.parsers.readline "\n"
		
		@serial.on 'open', =>
			debug "port open"
			@emit 'connected'
	
		@serial.on 'data', (data) =>
			debug "rx: #{data}"
			@emit 'data', "#{data}"
		
		@serial.on 'error', (err) =>
			debug "error: #{err}"
			@emit 'error', err
	
	write: (data) ->
		debug "tx: #{data}"
		@serial.write data
	
	close: ->
		debug "closing serial port"
		@serial.removeAllListeners()
		@serial.close (err) ->
			debug err


module.exports = SerialPort
