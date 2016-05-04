{nx}   = require 'nexus-node'
Entity = require '../common/entity'
SyncType = require '../common/sync-type'

class Service

	constructor: ({@transport, @log, entities}) ->
		@subscriptions = new Map

		@broadcast = new nx.Cell
			action: ({session, id, data}) =>
				subscription = @subscriptions.get session
				if id in subscription
					@transport.broadcast session, id, data

		send_everyone = ({id, data}) ->
			@log
				type: 'broadcast'
				session: session
				data: data

			session: null
			id:      id
			data:   data

		@entities = {}
		for id, data of entities
			entity = new Entity id, data
			entity.cell['->'] @broadcast, send_everyone
			entity.live_cell?['->'] @broadcast, send_everyone
			@entities[id] = entity

		@transport.on 'subscribe', (session, ids) => @subscribe session, ids
		@transport.on 'sync', (session, entities) => @sync session, entities

	subscribe: (session, ids) ->
		@subscriptions.set session, ids
		snapshot = Entity.make_snapshot @entities, ids
		session_snapshot = Entity.make_snapshot session.entities, ids
		@log
			type: 'batch'
			session: session
			data: { snapshot, session_snapshot }
		@transport.sync_batch session.id, snapshot
		@transport.sync_batch session.id, session_snapshot

	sync: (session, entities) ->
		@log
			type: 'sync'
			session: session
			data: entities
		for id, data of entities
			entity = @entities[id]
			if entity?
				entity.sync data
				@transport.broadcast session, id, data
			else
				session.sync id, data

module.exports = Service
