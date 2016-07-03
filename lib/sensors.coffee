Thermometer = require 'therm-ds18b20'
fs = require 'fs'
path = require 'path'
debug = require('debug')('webcut:printer')

temp = null

# scan for temp sensors
fs.readdir '/sys/bus/w1/devices/', (err, files) ->
	if err
		debug "Could not scan for 1wire devices: #{err}"
		return
	
	for dir in files when dir.match /28/
		id = path.basename dir
		sensor = new Thermometer
			id: id
			interval: 30000 # every 30s
		sensor.on 'data', (data) ->
			temp = data.C
		sensor.run()

module.exports =
	temperature: (-> temp)
