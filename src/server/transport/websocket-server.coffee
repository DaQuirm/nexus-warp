http            = require 'http'
{EventEmitter}  = require 'events'
Server          = require('websocket').server

class WebSocketServer extends EventEmitter

	constructor: (@options) ->

	start: ->
		@http_server = @options.server

		@websocket_server = new Server
			httpServer: @http_server

		@websocket_server.on 'request', (request) =>
			connection = request.accept '', request.origin
			@emit 'connection', connection

			connection.on 'message', (message) =>
				@emit 'message', message.utf8Data, connection

			connection.on 'close', => @emit 'close', connection

module.exports = WebSocketServer
