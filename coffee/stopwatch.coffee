class Timer

	offset   : null
	clock    : null
	interval : null
	delay    : null
	el       : null

	constructor: ( element, delay ) ->

		@el    = element
		@delay = delay

		@reset()


	start: ->

		if !interval
			@offset   = Date.now()
			@interval = setInterval @update, @delay


	stop: ->

		if @interval
			clearInterval @interval
			@interval = null


	reset: ->

		@clock = 0
		@render()


	update: ->

		@clock += @delta()
		@render()


	render: ->

		el.innerHTML = @clock / 1000


	delta: ->

		now = Date.now()
		d   = now - @offset

		@offset = now

		return d