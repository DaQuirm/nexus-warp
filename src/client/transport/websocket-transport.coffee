class WebSocketTransport

	constructor: (@options) ->
		@socket = new WebSocket @options.address
		@socket.onmessage = ({data}) =>
			message = JSON.parse data
			if message.msg is 'sync'
				@sync message

		@message_queue = []
		@socket.onopen = =>
			@message_queue.forEach (message) =>
				@send message

	send: (message) ->
		if @socket.readyState is WebSocket.OPEN
			@socket.send JSON.stringify(message)
		@message_queue.push message

	# Senders

	subscribe: (ids, onsync) ->
		@options.onsync = onsync
		@send
			msg: 'subscribe'
			ids: ids

	publish: (id, value) ->
		entity = {}
		entity[id] = value
		@send
			msg: 'sync'
			entities: entity


	# Handlers

	sync: ({entities}) ->
		for id, value of entities
			@options.onsync id, value

module.exports = WebSocketTransport
