{EventEmitter}  = require 'events'
WebSocketServer = require './websocket-server'
uuid            = require 'node-uuid'

class WebSocketTransport extends EventEmitter

	constructor: (@options) ->
		@sessions = new Map
		@connections = new Map
		@message_queues = new Map

		@server = new WebSocketServer
			server: @options.http_server

		@server.on 'connection', (connection, request) =>
			@message_queues.set connection, []
			session_id = do uuid.v1
			@connections.set session_id, connection
			@options.session_manager.create @, session_id, request.cookies, (err, session) =>
				unless err
					@sessions.set connection, session
					message_queue = @message_queues.get connection
					message_queue.forEach (message) =>
						@["on#{message.msg}"] session, message
					@message_queues.delete connection
				else
					@message_queues.delete connection
					@connections.delete session_id
					connection.close connection.CLOSE_REASON_NORMAL, err.message

		@server.on 'message', (data, connection) =>
			message = JSON.parse data
			session = @sessions.get connection
			if not session?
				message_queue = @message_queues.get connection
				message_queue.push message
			else
				@["on#{message.msg}"] @sessions.get(connection), message

		@server.on 'close', (connection) =>
			session = @sessions.get connection
			if session
				do session.destroy
				@connections.delete session.id
				@sessions.delete connection

		do @server.start

	# Handlers
	onsubscribe: (session, {ids}) ->
		@emit 'subscribe', session, ids

	onsync: (session, {entities}) ->
		@emit 'sync', session, entities

	# Senders
	send: (session_id, message) =>
		if @connections.has session_id
			connection = @connections.get session_id
			connection.sendUTF JSON.stringify(message)

	broadcast: (sender_session, id, value) ->
		@sessions.forEach (session) =>
			if session isnt sender_session
				@sync session, id, value

	sync: (session_id, id, value) ->
		@send session_id,
			msg: 'sync'
			entities:
				"#{id}": value

	sync_batch: (session_id, entities) ->
		@send session_id,
			msg: 'sync'
			entities: entities

module.exports = WebSocketTransport
