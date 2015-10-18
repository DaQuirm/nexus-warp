{nx}   = require 'nexus-node'
Entity = require '../common/entity'
SyncType = require '../common/sync-type'

class Service

	constructor: ({@transport, entities}) ->
		@subscriptions = new Map

		@broadcast = new nx.Cell
			action: ({session, id, data}) =>
				@transport.broadcast session, id, data

		send_everyone = ({id, data}) ->
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
		snapshot = @make_snapshot @entities, session.entities
		@transport.sync_batch session, snapshot

	sync: (session, entities) ->
		for id, data of entities
			entity = @entities[id]
			if entity?
				entity.sync data
				@transport.broadcast session, id, data
			else
				session.sync id, data

	make_snapshot: (entities, session_entities) ->
		snapshot = {}
		for id, entity of entities
			snapshot[id] =
				type: SyncType.LINK
				value: do entity.to_json
		for id, entity of session_entities
			snapshot[id] =
				type: SyncType.LINK
				value: do entity.to_json
		snapshot

module.exports = Service
