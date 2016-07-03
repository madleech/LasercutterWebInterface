{EventEmitter} = require 'events'

class Radio extends EventEmitter
	constructor: ->
		@errors = []
		@on 'error', (err) -> @errors.push err
	broadcast: -> @emit.apply @, arguments

module.exports = new Radio
