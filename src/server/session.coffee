{nx} = require 'nexus-node'

Entity = require '../common/entity'

class Session

	constructor: ({facet, @transport}) ->
		@send = new nx.Cell
			action: ({id, data}) => @transport.sync @, id, data

		@entities = {}
		@session_facet = facet
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
		for name, entity of entities
			do entity.unlink
			delete @entities[name]

	process_dynamic_entities: (entities) ->
		cell = new nx.Cell
			'<-': [entities]
			action: (new_entities, old_entities) =>
				if old_entities?
					@remove_entities old_entities
				if new_entities?
					@add_entities new_entities
					ids = Object.keys new_entities
					snapshot = Entity.make_snapshot @entities, ids
					@transport.sync_batch @, snapshot

	sync: (id, value) ->
		@entities[id].sync value

	init: ->
		@session_facet.init @

	destroy: ->
		@remove_entities @entities
		@session_facet.destroy @

module.exports = Session
