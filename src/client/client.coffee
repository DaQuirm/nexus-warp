{nx} = require 'nexus'

Entity = require '../common/entity'

class Client
	constructor: ({@transport, entities}) ->

		@sync = new nx.Cell
			action: ({id, data}) => @transport.publish id, data

		@entities = {}
		for id, data of entities
			entity = new Entity id, data
			entity.cell['->'] @sync
			entity.live_cell?['->'] @sync
			@entities[id] = entity

		@transport.subscribe Object.keys(@entities), (id, data) => @entities[id].sync data

module.exports = Client
