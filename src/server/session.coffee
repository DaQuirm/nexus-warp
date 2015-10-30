{nx} = require 'nexus-node'

Entity = require '../common/entity'

class Session

	constructor: ({@facet, @transport, entities}) ->
		sync = new nx.Cell
			action: ({id, data}) => @transport.sync @, id, data

		@entities = {}
		for id, data of entities
			entity = new Entity id, data
			entity.cell['->'] sync
			entity.live_cell?['->'] sync
			@entities[id] = entity

	sync: (id, value) ->
		@entities[id].sync value

	init: ->
		@facet.init @

	destroy: ->
		@facet.destroy @

module.exports = Session
