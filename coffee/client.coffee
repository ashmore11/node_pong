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
		if !@interval
			@offset   = Date.now()
			@interval = setInterval @update, @delay

	stop: ->

		if @interval
			clearInterval @interval
			@interval = null

	reset: ->
		@clock = 0
		@render()

	update: =>
		@clock += @delta()
		@render()

	render: ->
		@el.html @clock / 1000

	delta: ->
		now = Date.now()
		d   = now - @offset

		@offset = now

		return d

class App

	window              : null
	pong_stage          : null
	single_player       : null
	multiplayer         : null
	user_div            : null
	disconnect_div      : null
	socket              : null
	canvas              : null
	stage               : null
	images              : null
	title_view          : null
	total_loaded        : 0
	user_id             : null
	timer               : null
	score               : 0
	high_score          : null
	score_alert         : null
	x_speed             : null
	y_speed             : null
	single_player_mode  : true
	single_player_timer : null
	paddle_1_disabled   : false
	paddle_2_disabled   : false

	constructor: ->

		@window         = $ window
		@pong_stage     = $ '#PongStage'
		@single_player  = $ '#single_player'
		@multiplayer    = $ '#multiplayer'
		@wait           = $ '#wait'
		@max_users      = $ '#max_users'
		@user_div       = $ '#user_div'
		@disconnect_div = $ '#disconnect_div'
		@high_score     = $ '#high_score'
		@score_alert    = $ '#score_alert'

		@x_speed = 12
		@y_speed = 10

		@single_player.css top: ( @window.height() / 2 ) + 5

		@window.on 'touchmove', ( event ) -> event.preventDefault()
		@window.on 'resize', @on_resize()

		@create_stage()

		@multiplayer.on 'click', =>

			@single_player_mode = false

			@handle_users()

		@single_player.on 'click', =>

			@single_player_mode = true

			@timer = new Timer $('#timer'), 10
			@hide_title_view()


	handle_users: ->

		@socket = io.connect 'http://scott.local:3700'

		@socket.on 'connect', () =>

			@multiplayer.animate opacity: 0, -> $( @ ).hide()

			@wait.animate opacity: 1, marginTop: -95, 1000

			@socket.emit 'adduser', prompt "What's your name?"

			@socket.on 'updateusers', ( user ) =>

				html = user + ' has joined the game!'

				@user_div
					.html    html
					.fadeIn  1000
					.delay   1000
					.fadeOut 1000, => $( @ ).html ''

			@socket.on 'user_disconnect', ( user ) =>

				html = user + ' has disconnected...'

				@disconnect_div
					.html    html
					.fadeIn  1000
					.delay   1000
					.fadeOut 1000, => $( @ ).html ''

				@reset_game()

				@single_player.show -> $( @ ).animate opacity: 1
				@multiplayer.show   -> $( @ ).animate opacity: 1

		@socket.on 'user_num', ( user_num ) =>

			if user_num is 2 then @socket.emit 'players_ready'

			@socket.on 'start_game', => @players_ready()

		@socket.on 'player_1_score', () => @player_one_score()
		@socket.on 'player_2_score', () => @player_two_score()

		@socket.on 'max_users', ( user ) => @too_many_users user

		@socket.on 'disable_paddle_1', => @paddle_1_disabled = true
		@socket.on 'disable_paddle_2', => @paddle_2_disabled = true


	too_many_users: ( user ) ->

		@wait.hide()
		@max_users.show().animate opacity: 1


	create_stage: ->

		@canvas = document.getElementById 'PongStage'
		@stage  = new Stage @canvas

		@stage.canvas.width  = @window.width()
		@stage.canvas.height = @window.height()

		@images = [
			{ id:'player_1',     src:'images/paddle.png' },
			{ id:'player_2',     src:'images/paddle2.png' },
			{ id:'ball',         src:'images/ball.png' },
			{ id:'player_1_win', src:'images/player_1_win.png' },
			{ id:'player_2_win', src:'images/player_2_win.png' }
		]

		preloader = new PreloadJS()
		preloader.onFileLoad = @handle_file_load
		preloader.loadManifest @images

		Ticker.setFPS 60
		Ticker.addListener @stage


	handle_file_load: ( e ) =>

		switch e.type
			when PreloadJS.IMAGE
				img            = new Image()
				img.src        = e.src
				img.onload     = @handle_load_complete()
				window[ e.id ] = new Bitmap img

				@handle_load_complete()


	handle_load_complete: =>

		@total_loaded++

		if @images.length is @total_loaded then @add_title_view()


	add_title_view: ->

		@single_player.animate opacity: 1
		@multiplayer.animate   opacity: 1

		@title_view = new Container()
		@stage.addChild @title_view


	players_ready: ->

		@single_player_mode = false

		@delay 1000, => @hide_title_view()


	hide_title_view: =>

		@multiplayer.animate opacity: 0,   -> $( @ ).hide()
		@single_player.animate opacity: 0, -> $( @ ).hide()
		@wait.animate opacity: 0,          -> $( @ ).hide()
		@max_users.animate opacity: 0,     -> $( @ ).hide()
		
		if @title_view != null
			Tween.get( @title_view ).to y: -( ( @window.height() / 2 ) + 45 ), 500
		
		@delay 500, => @add_game_view()


	add_game_view: ->

		@pong_stage.css opacity: 0
		
		@stage.removeChild @title_view
		@title_view = null

		w     = @window.width()  / 5
		h     = @window.height() / 5
		ow    = 145
		oh    = 1129
		scale = Math.min w / ow, h / oh

		player_1.scaleX = scale
		player_1.scaleY = scale
		player_1.x      = 0
		player_1.y      = @window.height() / 2
		player_1.regY   = player_1.image.height / 2

		player_2.scaleX = scale
		player_2.scaleY = scale
		player_2.x      = @window.width() - ( player_2.image.width * scale )
		player_2.y      = @window.height() / 2
		player_2.regY   = player_2.image.height / 2

		w     = @window.width()  / 10
		h     = @window.height() / 10
		ow    = 245
		oh    = 400
		scale = Math.min w / ow, h / oh

		ball.scaleX = scale
		ball.scaleY = scale

		ball.x = @window.width()  / 2
		ball.y = @window.height() / 2

		ball.regX = ball.image.width  / 2
		ball.regY = ball.image.height / 2

		if @single_player_mode

			@stage.addChild player_1, player_2, ball

		else

			@player_1_score           = new Text '0', '20px Arial', '#FFF'
			@player_1_score.x         = ( @window.width() / 2 ) - 15
			@player_1_score.y         = 20
			@player_1_score.textAlign = 'right'

			@player_2_score           = new Text '0', '20px Arial', '#FFF'
			@player_2_score.x         = ( @window.width() / 2 ) + 15
			@player_2_score.y         = 20
			@player_2_score.textAlign = 'left'

			@stage.addChild @player_1_score, @player_2_score, player_1, player_2, ball

		@pong_stage.animate opacity: 1, 500

		if @single_player_mode is false
			@move_paddle_1()
			@move_paddle_2()

		@paddle_events()
		@trigger_game()


	trigger_game: ->

		ball.onPress = =>
			if @single_player_mode then @start_game() else @socket.emit 'ball_pressed'
		
		if @single_player_mode is false
			@socket.on 'game_started', =>
				@start_game()


	paddle_events: ->

		@window.on 'touchstart touchmove mousedown mousemove', ( event ) =>

			page_y = event.originalEvent.pageY
			page_x = event.originalEvent.pageX

			percent = ( page_y / @window.height() ) * 100

			if @single_player_mode	
				@single_player_paddle page_y
			else
				if @paddle_1_disabled is false
					@socket.emit 'move_1', percent

				if @paddle_2_disabled is false
					@socket.emit 'move_2', percent


	move_paddle_1: ->

		@socket.on 'paddle_1', ( percent ) =>

			w     = @window.width() / 5
			h     = @window.height() / 5
			ow    = 145
			oh    = 1129
			scale = Math.min w / ow, h / oh

			page_y     = ( percent / 100 ) * @window.height()
			player_1.y = page_y
			bottom     = @window.height() - ( player_1.image.height * scale ) / 2
			top        = ( player_1.image.height * scale ) / 2

			if player_1.y >= bottom then player_1.y = bottom
			if player_1.y <= top    then player_1.y = top


	move_paddle_2: ->

		@socket.on 'paddle_2', ( percent ) =>

			w     = @window.width() / 5
			h     = @window.height() / 5
			ow    = 145
			oh    = 1129
			scale = Math.min w / ow, h / oh

			page_y     = ( percent / 100 ) * @window.height()
			player_2.y = page_y
			bottom     = @window.height() - ( player_2.image.height * scale ) / 2
			top        = ( player_2.image.height * scale ) / 2

			if player_2.y >= bottom then player_2.y = bottom
			if player_2.y <= top    then player_2.y = top


	single_player_paddle: ( page_y ) ->

		w     = @window.width()  / 5
		h     = @window.height() / 5
		ow    = 145
		oh    = 1129
		scale = Math.min w / ow, h / oh

		player_1.y = page_y
		bottom     = @window.height() - ( player_1.image.height * scale ) / 2
		top        = ( player_1.image.height * scale ) / 2

		if player_1.y >= bottom then player_1.y = bottom
		if player_1.y <= top    then player_1.y = top


	start_game: ->

		if @single_player_mode

			@timer.start()

			@single_player_timer = setInterval( =>
				@single_player_update()
			, 15 )

		else

			@socket.on 'ballmove', ( x , y ) =>
				
				ball.x = ( x / 100 ) * @window.width()
				ball.y = ( y / 100 ) * @window.height()

		Tween.get( ball, loop: true ).to rotation: 360, 1000

		@tween_ball()


	tween_ball: ->

		if @single_player_mode is false

			@socket.on 'paddle_hit', ->

				Tween.removeTweens ball
				Tween.get( ball, loop: true ).to rotation: 360, 1000

			@socket.on 'wall_hit', ->

				Tween.removeTweens ball
				Tween.get( ball, loop: true ).to rotation: -360, 1000


	player_one_score: =>

		Tween.removeTweens ball
		Tween.get( ball ).to rotation: 0, 1

		@player_1_score.text = parseInt @player_1_score.text + 1

		ball.x    = @window.width()   / 2
		ball.y    = @window.height()  / 2
		ball.regX = ball.image.width  / 2
		ball.regY = ball.image.height / 2

		if @player_1_score.text is 3

			player_1_win.x = ( @window.width()  / 2 ) - 100
			player_1_win.y = ( @window.height() / 2 )

			@stage.addChild player_1_win
			Tween.get( player_1_win ).to y: ( @window.height() / 2 ) - 45, 500

			@reset_game()

		
	player_two_score: =>

		Tween.removeTweens ball
		Tween.get( ball ).to rotation: 0, 1

		ball.x = @window.width()  / 2
		ball.y = @window.height() / 2

		if @single_player_mode

			clearInterval @single_player_timer
			@single_player_score $('#timer').html()
			@timer.stop()
			@timer.reset()

		else

			@player_2_score.text = parseInt @player_2_score.text + 1

			if @player_2_score.text is 3

				player_2_win.x = ( @window.width()  / 2 ) - 100
				player_2_win.y = ( @window.height() / 2 )

				@stage.addChild player_2_win
				Tween.get( player_2_win ).to y: ( @window.height() / 2 ) - 45, 500

				@reset_game()


	single_player_score: ( score ) ->

		if score > @score
			@high_score.html 'HIGH SCORE: ' + score + ' SECONDS'

			html = 'NEW HIGH SCORE!'

		else
			@high_score.html 'HIGH SCORE: ' + @score + ' SECONDS'

			html = 'YOU SUCK!'

		@score_alert
			.html    html
			.fadeIn  1000 
			.delay   2500 
			.fadeOut 1000, => $( @ ).html ''

		@score = score


	reset_game: ->

		if @single_player_mode is false

			@stage.removeChild @player_1_score, @player_2_score

			@player_1_score           = new Text '0', '20px Arial', '#FFF'
			@player_1_score.x         = ( @window.width() / 2 ) - 15
			@player_1_score.y         = 20
			@player_1_score.textAlign = 'right'

			@player_2_score           = new Text '0', '20px Arial', '#FFF'
			@player_2_score.x         = ( @window.width() / 2 ) + 15
			@player_2_score.y         = 20
			@player_2_score.textAlign = 'left'

			@stage.addChild @player_1_score, @player_2_score

			player_1_win.onPress = =>
				@socket.emit 'remove_win'
			
			@socket.on 'remove', ->
				Tween.get( player_1_win ).to y: -115, 300

			player_2_win.onPress = =>
				@socket.emit 'remove_win'
			
			@socket.on 'remove', ->
				Tween.get( player_2_win ).to y: -115, 300

		ball.onPress = =>
			if @single_player_mode
				@start_game()
			else
				@socket.emit 'ball_pressed'


	increase_speed: ( axis ) ->

		speed = Math.floor( ( axis * -1.02 ) * 100 ) / 100

		return speed


	single_player_update: ->

		ball.x = ball.x + @x_speed
		ball.y = ball.y + @y_speed

		player_2.y = ball.y

		player_w     = @window.width()  / 5
		player_h     = @window.height() / 5
		player_ow    = 145
		player_oh    = 1129
		player_scale = Math.min player_w / player_ow, player_h / player_oh

		player_width  = player_1.image.width  * player_scale
		player_height = player_1.image.height * player_scale

		ball_w     = @window.width()  / 10
		ball_h     = @window.height() / 10
		ball_ow    = 245
		ball_oh    = 400
		ball_scale = Math.min ball_w / ball_ow, ball_h / ball_oh

		ball_width  = ball.image.width  * ball_scale
		ball_height = ball.image.height * ball_scale

		if ball.y <= ball_width / 2
			@y_speed = @increase_speed @y_speed
			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: -360, 1000
		
		if ball.y >= @window.height() - ( ball_width / 2 )
			@y_speed = @increase_speed @y_speed
			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: -360, 1000

		if ball.x < player_width + ( ball_width / 2 ) and ball.y > player_1.y - ( player_height ) / 2 and ball.y < player_1.y + ( player_height / 2 )
			@x_speed = @increase_speed @x_speed
			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: 360, 1000

		if ball.x > @window.width() - ( player_width + ( ball_width / 2 ) ) and ball.y > player_2.y - ( player_height / 2 ) and ball.y < player_2.y + ( player_height / 2 )
			@x_speed = @increase_speed @x_speed
			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: 360, 1000

		if ball.x < player_width
			if @y_speed < 0 then @y_speed = 10 else @y_speed = -10
			@x_speed = 12
			@player_two_score()


	delay: ( time, fn, args ) ->
		
		setTimeout fn, time, args


	on_resize: ->

		$('body').animate scrollTop: 0, 1000


$ -> app = new App

