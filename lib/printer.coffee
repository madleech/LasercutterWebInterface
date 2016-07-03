# printer interface

SerialPort = require './serial'
{EventEmitter} = require 'events'
debug = require('debug')('webcut:printer')

UNCONNECTED = 'UNCONNECTED'
RESET = 'RESET'
LOCKED = 'LOCKED'
UNLOCKED = 'UNLOCKED'
HOMING = 'HOMING'
RESET_REQUIRED = 'RESET_REQUIRED'
HOMED = 'HOMED'

# connect to grbl
# -> 0x18 - reset command
# <- Grbl 0.9i
# ?<- ['$H'|'$X' to unlock]
# -> $H
# ?<- [Caution: Unlocked]
# <- ok
# ~> error if not ok

class Printer extends EventEmitter
	constructor: (port, speed=57600, connect_timeout=30000) ->
		@progress UNCONNECTED
		@port = new SerialPort(port, speed)
		
		# timeout handler
		setTimeout (=> @emit 'error', "Failed to connect after #{connect_timeout}ms" if @state == UNCONNECTED), connect_timeout
		
		# connect
		@port.on 'connected', =>
			# send soft reset
			@soft_reset()
		
		# handle receive events
		@port.on 'data', (data) =>
			if data.match /Grbl/
				@transition RESET
			else if data.indexOf("['$H'|'$X' to unlock]") == 0
				@transition LOCKED
			else if data.indexOf("[Caution: Unlocked]") == 0
				@transition UNLOCKED
			else if data.indexOf("ok") == 0
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
				@emit 'error', "unknown response: #{data}"
		
		# handle transmit events
		@on 'state', (state) ->
			switch state
				when RESET then {}
				when LOCKED then @home()
				when UNLOCKED then @emit 'ready'
				when HOMED then @emit 'ready'
	
	soft_reset: ->
		# send soft reset
		@progress 'sending soft reset'
		@port.write 0x18
	
	transition: (new_state) ->
		debug "transitioning to #{new_state}"
		@state = new_state
		@emit 'state', new_state
	
	progress: (message) ->
		debug "progress: #{message}"
		@emit 'progress', message
	
	write: (line) ->
		@port.write line
	
	home: (cb) ->
		@progress 'Homing'
		@transition HOMING
		@port.write '$H', cb
	
	unlock: (cb) ->
		@progress 'Unlocking'
		@port.write '$X', cb
	
	reset: (mm, cb) ->
		@port.write "G0 Z#{mm}", cb
	
	status: ->
		@port.write '?'
	
	close: ->
		@port.close()
		@port.removeAllListeners()
	

module.exports = Printer
