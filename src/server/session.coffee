{nx} = require 'nexus-node'

Entity = require '../common/entity'

class Session

	constructor: ({facet, @transport}) ->
		@session_facet = facet
		@sync = new nx.Cell
			action: ({id, data}) => @transport.sync @, id, data
		if @is_plain_facet facet
			@add_entities facet.entities
		else
			@process_facet facet

	add_entities: (entities) ->
		for id, data of entities
			entity = new Entity id, data
			entity.cell['->'] @sync
			entity.live_cell?['->'] @sync
			@entities[id] = entity

	remove_entities: (entities) ->
		for name, entity of entities
			do entity.unlink
			delete @entities[name]

	is_plain_facet: ({morph, capture}) ->
		not morph? and not capture?

	process_facet: ({facet, capture, morph}) ->
		cells = capture.map (cell_name) -> facet[cell_name]
		cell = new nx.Cell
			'<-': [cells, morph]
			action: (new_facet, old_facet) =>
				if old_facet?
					@remove_entities old_facet.entities
				if new_facet?
					@add_entities new_facet.entities

	sync: (id, value) ->
		@entities[id].sync value

	init: ->
		@session_facet.init @

	destroy: ->
		@session_facet.destroy @

module.exports = Session
