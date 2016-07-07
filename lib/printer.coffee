# printer interface

SerialPort = require './serial'
{EventEmitter} = require 'events'
debug = require('debug')('webcut:printer')

DISCONNECTED = 'DISCONNECTED'
RESET = 'RESET'
LOCKED = 'LOCKED'
UNLOCKED = 'UNLOCKED'
HOMING = 'HOMING'
RESET_REQUIRED = 'RESET_REQUIRED'
HOMED = 'HOMED'
READY = 'READY'

# connect to grbl
# -> 0x18 - reset command
# <- Grbl 0.9i
# ?<- ['$H'|'$X' to unlock]
# -> $H
# ?<- [Caution: Unlocked]
# <- ok
# ~> error if not ok

class Printer extends EventEmitter
	constructor: (@device = process.env.DEVICE) ->
		@port = new SerialPort(@device)
		@state = DISCONNECTED
		
		@port.on 'connected', => @soft_reset()
		
		# handle receive events
		@port.on 'data', (data) =>
			if data.match /Grbl/
				@transition RESET
			else if data.indexOf("['$H'|'$X' to unlock]") == 0
				@transition LOCKED
			else if data.indexOf("[Caution: Unlocked]") == 0
				@transition UNLOCKED
			else if data.match "ok"
				if @state == HOMING
					@transition HOMED
				else
					@emit 'ok'
			else if data.match /^error/
				@emit 'error', data
			else if data.match /^ALARM/
				@emit 'alarm', data
			else if data.indexOf("[Reset to continue]") == 0
				@transition RESET_REQUIRED
			else
				debug "unknown response: #{data}"
		
		# handle transmit events
		@on 'state', (state) ->
			switch state
				when RESET then {}
				when LOCKED then @home()
				when UNLOCKED then @transition READY
				when HOMED then @transition READY
				when READY then @emit 'ready'
	
	connect: (connect_timeout=10000) ->
		debug "About to connect, state is #{@state}"
		if @state is READY
			@emit 'ready'
			return
		
		debug "Connecting to #{@device}"
		@progress DISCONNECTED
		
		# timeout handler
		setTimeout (=> @emit 'error', "Failed to connect after #{connect_timeout}ms" if @state == DISCONNECTED), connect_timeout
		
		# send soft reset once connected
		if @port.isOpen()
			debug "Port already open, sending soft reset"
			@soft_reset()
		else
			debug "Opening port before sending soft reset"
			@port.open()
	
	soft_reset: ->
		# send soft reset
		@progress 'sending soft reset'
		@port.serial.write new Buffer([0x18])
	
	transition: (new_state) ->
		debug "transitioning to #{new_state}"
		@state = new_state
		@emit 'state', new_state
	
	progress: (message) ->
		debug "progress: #{message}"
		@emit 'progress', message
	
	write: (line) ->
		@port.write "#{line}\n"
	
	home: (cb) ->
		@transition HOMING
		@progress 'Homing'
		@port.write "$H\n", cb
	
	unlock: (cb) ->
		@progress 'Unlocking'
		@port.write "$X\n", cb
	
	reset: (mm, cb) ->
		@port.write "G0 Z#{mm}\n", cb
	
	status: ->
		@port.write "?\n"
	
	close: ->
		@transition DISCONNECTED
		@port.close()

module.exports = new Printer
