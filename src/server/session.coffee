{nx} = require 'nexus-node'

Entity = require '../common/entity'

class Session

	constructor: ({facet, @transport, @log, @id}) ->
		@send = new nx.Cell
			action: ({id, data}) =>
				@log
					type: 'session-sync'
					session: @
					data: data
				@transport.sync @id, id, data

		@entities = {}
		@facet = facet
		@add_entities facet.entities

		if facet.dynamic_entities?
			@process_dynamic_entities facet.dynamic_entities

	add_entities: (entities) ->
		for id, data of entities
			entity = new Entity id, data
			entity.cell['->'] @send
			entity.live_cell?['->'] @send
			@entities[id] = entity

	remove_entities: (entities) ->
		for name, _ of entities when @entities[name]
			do @entities[name].unlink
			delete @entities[name]

	process_dynamic_entities: (entities) ->
		cell = new nx.Cell
			action: (new_entities, old_entities) =>
				if old_entities?
					@remove_entities old_entities
				if new_entities?
					@add_entities new_entities
					ids = Object.keys new_entities
					snapshot = Entity.make_snapshot @entities, ids
					@transport.sync_batch @id, snapshot
		@dynamic_entities_binding = cell['<-'] entities

	sync: (id, value) ->
		@entities[id].sync value

	init: ->
		@facet.init @

	destroy: ->
		@facet.destroy @
		@remove_entities @entities
		do @dynamic_entities_binding?.unbind

module.exports = Session
