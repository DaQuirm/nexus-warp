{nx}       = require 'nexus-node'
EntityType = require './entity-type'
SyncType   = require './sync-type'

class Entity

	constructor: (@id, data) ->
		@type = Entity.get_type data
		@resource = Entity.get_link data
		@link = Entity.get_link_cell data

		@cell = new nx.Cell

		@serialization =
			to_json: data.to_json
			from_json: data.from_json
			item_to_json: data.item_to_json
			item_from_json: data.item_from_json

		@binding = @link['->'] @cell, (value) =>
			json = @value_to_json value

			id: @id
			data:
				value: json
				type:  SyncType.LINK

		if @type is EntityType.COLLECTION
			@live_binding = Entity.create_live_binding @id, data
			@live_cell = @live_binding?.target

	sync: ({value, type}) ->
		switch type

			when SyncType.LINK
				value = @value_from_json value
				do @binding.lock
				@link.value = value
				do @binding.unlock

			when SyncType.LIVE
				{index, cell, value} = value
				@resource.items[index][cell].value = value

	value_to_json: (value) ->
		{to_json, item_to_json} = @serialization
		if @type is EntityType.CELL and to_json?
			to_json value
		else if @type is EntityType.COLLECTION and item_to_json? # value is an nx.Command
			nx.Collection.mapCommand value, item_to_json
		else
			value

	value_from_json: (value) ->
		{from_json, item_from_json} = @serialization
		if @type is EntityType.CELL
			if from_json?
				from_json value
			else
				value
		else if @type is EntityType.COLLECTION
			if item_from_json? # value is an nx.Command
				nx.Collection.mapCommand value, item_from_json
			else
				nx.Collection.mapCommand value, nx.Identity # deserialize nx.Command

	to_json: ->
		if @serialization.to_json?
			@serialization.to_json @link.value
		else if @type is EntityType.COLLECTION
			items =
				if @serialization.item_to_json?
					@resource.items.map @serialization.item_to_json
				else
					@resource.items
			new nx.Command 'reset', items:items
		else
			@link.value

	unlink: ->
		do @binding.unbind
		do @live_binding?.unbind

	# Static methods

	@get_link: (entity) -> entity.link or entity

	@get_type: (entity) ->
		link = Entity.get_link entity
		# if link instanceof nx.Cell
		# 	EntityType.CELL
		# else if link instanceof nx.Collection
		# 	EntityType.COLLECTION
		# else if link instanceof nx.RefinedCollection
		# 	EntityType.COLLECTION

		if link.length?
			EntityType.COLLECTION
		else
			EntityType.CELL

	@get_link_cell: (entity) ->
		link = Entity.get_link entity
		type = Entity.get_type entity
		switch type
			when EntityType.CELL then	link
			when EntityType.COLLECTION then link.command

	@create_live_binding: (id, entity) ->
		resource = Entity.get_link entity
		if resource.transform.change? # nx.LiveTransform
			live_cell = new nx.Cell

			resource.transform.change['->'] live_cell, ({item, cell, value}) ->
				index = resource.items.indexOf item
				json =
					index: index
					cell: cell
					value: value

				id: id
				data:
					value: json
					type:  SyncType.LIVE

	@make_snapshot: (entities, ids) ->
		snapshot = {}
		for id in ids when entities[id]?
			value = do entities[id].to_json
			if value?
				snapshot[id] =
					type: SyncType.LINK
					value: value
		snapshot

module.exports = Entity
