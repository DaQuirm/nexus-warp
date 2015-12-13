{EventEmitter}  = require 'events'
WebSocketServer = require './websocket-server'

class WebSocketTransport extends EventEmitter

	constructor: (@options) ->
		@sessions = new Map
		@connections = new Map
		@message_queues = new Map

		@server = new WebSocketServer
			server: @options.http_server

		@server.on 'connection', (connection, request) =>
			@message_queues.set connection, []
			@options.session_manager.create @, request.cookies, (session) =>
				@sessions.set connection, session
				@connections.set session, connection
				message_queue = message_queues.get connection
				message_queue.forEach (message) =>
					@["on#{message.msg}"] session, message
				message_queues.delete connection

		@server.on 'message', (data, connection) =>
			message = JSON.parse data
			session = @sessions.get connection
			if not session?
				message_queue = message_queues.get connection
				message_queue.push message
			else
				@["on#{message.msg}"] @sessions.get(connection), message

		@server.on 'close', (connection) =>
			session = @sessions.get connection
			do session.destroy
			@connections.delete session
			@sessions.delete connection

		do @server.start

	# Handlers
	onsubscribe: (session, {ids}) ->
		@emit 'subscribe', session, ids

	onsync: (session, {entities}) ->
		@emit 'sync', session, entities

	# Senders
	send: (session, message) ->
		connection = @connections.get session
		connection.sendUTF JSON.stringify(message)

	broadcast: (sender_session, id, value) ->
		@sessions.forEach (session) =>
			if session isnt sender_session
				@sync session, id, value

	sync: (session, id, value) ->
		@send session,
			msg: 'sync'
			entities:
				"#{id}": value

	sync_batch: (session, entities) ->
		@send session,
			msg: 'sync'
			entities: entities

module.exports = WebSocketTransport
