class App

	window       : null
	pong_stage   : null
	socket       : null
	canvas       : null
	stage        : null
	images       : null
	title_view   : null
	total_loaded : 0

	constructor: ->

		@window     = $ window
		@pong_stage = $ '#PongStage'

		@window.on 'touchmove', ( event ) -> event.preventDefault()
		@window.on 'resize', @on_resize()

		@cc = window.cc = new CoffeeCollider

		@handle_users()
		@create_stage()


	handle_users: ->

		@socket = io.connect 'http://scott.local:3700'

		@socket.on 'connect', () =>
			@socket.emit 'adduser', prompt "What's your name?"

			@socket.on 'updateusers', ( user ) =>

				html = user + ' has joined the game!'

				$( '#userDiv' )
					.html    html 
					.fadeIn  1000 
					.delay   1000 
					.fadeOut 1000, => $( @ ).html ''

			@socket.on 'user_disconnect', ( user ) =>

				html = user + ' has disconnected...'

				$( '#disconnectDiv' )
					.html    html 
					.fadeIn  1000 
					.delay   1000 
					.fadeOut 1000, => $( @ ).html ''

				@reset_game()

		@socket.on 'user_num', ( user_num ) =>

			@delay 2000, => if user_num is 2 then @hide_title_view()

		@socket.on 'player_1_score', () => @player_one_score()
		@socket.on 'player_2_score', () => @player_two_score()


	create_stage: ->

		@canvas = document.getElementById 'PongStage'
		@stage  = new Stage @canvas

		@stage.canvas.width  = @window.width()
		@stage.canvas.height = @window.height()

		@images = [
			{ id:'wait',         src:'images/waiting.gif' },
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

		wait.x = ( @window.width() / 2 ) - 142
		wait.y = ( @window.height() / 2 )

		Tween.get( wait ).to y: ( @window.height() / 2 ) - 45, 500

		@title_view = new Container()
		@title_view.addChild wait
		@stage.addChild @title_view


	hide_title_view: =>
		
		if @title_view != null
			Tween.get( @title_view ).to y: -( ( @window.height() / 2 ) + 45 ), 500
		
		@delay 500, =>
			@add_game_view()


	add_game_view: ->

		@pong_stage.css opacity: 0
		
		@stage.removeChild @title_view
		@title_view = null

		w     = @window.width() / 5
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

		w     = @window.width() / 10
		h     = @window.height() / 10
		ow    = 245
		oh    = 400
		scale = Math.min w / ow, h / oh

		ball.scaleX = scale
		ball.scaleY = scale

		ball.x = @window.width() / 2
		ball.y = @window.height() / 2

		ball.regX = ball.image.width / 2
		ball.regY = ball.image.height / 2

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

		@move_paddle_1()
		@move_paddle_2()
		@paddle_events()
		@trigger_game()


	trigger_game: ->

		ball.onPress = =>
			@socket.emit 'ball_pressed'
		
		@socket.on 'game_started', =>
			@start_game()


	paddle_events: ->

		@window.on 'touchstart touchmove mousedown mousemove', ( event ) =>

			page_y = event.originalEvent.pageY
			page_x = event.originalEvent.pageX

			percent = ( page_y / @window.height() ) * 100

			if page_x < @pong_stage.width() / 2 then @socket.emit 'move_1', percent
			if page_x > @pong_stage.width() / 2 then @socket.emit 'move_2', percent


	start_game: ->

		@socket.on 'ballmove', ( x , y ) =>
			
			ball.x = ( x / 100 ) * @window.width()
			ball.y = ( y / 100 ) * @window.height()

		Tween.get( ball, loop: true ).to rotation: 360, 1000

		@trigger_audio()


	trigger_audio: ->

		# cc.run """

		# synth = SynthDef (freq)->

		# 	s = SinOscFB.ar( freq ) * Line.kr(1, 0, dur:0.5, doneAction:2)
		# 	s = s.dup()
		# 	Out.ar(0, s) * 0.5

		# .add()

		# p = Pseq( [ 55,0,0,0 ], Infinity )

		# Task ->
		# 	0.wait()
		# 	p.do syncblock (freq)->
		# 		# freq = (60 - 24 + i).midicps()

		# 		Synth(synth, freq:freq)

		# 		[0.5].choose().wait()
		# .start()

		# p = Pseq( [ 55,0,0,0,55*1.25 ], Infinity )

		# Task ->
		# 	0.2.wait()
		# 	p.do syncblock (freq)->
		# 		# freq = (60 - 24 + i).midicps()

		# 		Synth(synth, freq:freq)

		# 		[0.5].choose().wait()
		# .start()
		
		# """, on

		@socket.on 'paddle_hit', ->

			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: 360, 1000


		@socket.on 'wall_hit',   ->

			Tween.removeTweens ball
			Tween.get( ball, loop: true ).to rotation: -360, 1000


	move_paddle_1: ->

		@socket.on 'paddle_1', ( percent ) =>

			w     = @window.width() / 5
			h     = @window.height() / 5
			ow    = 145
			oh    = 1129
			scale = Math.min w / ow, h / oh

			page_y     = ( percent / 100 ) * @window.height()
			player_1.y = page_y
			bottom     = @window.height() - ( ( player_1.image.height * scale ) / 2 )
			top        = 0 + ( ( player_1.image.height * scale ) / 2 )

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
			bottom     = @window.height() - ( ( player_2.image.height * scale ) / 2 )
			top        = 0 + ( ( player_2.image.height * scale ) / 2 )

			if player_2.y >= bottom then player_2.y = bottom
			if player_2.y <= top    then player_2.y = top


	player_one_score: =>

		Tween.removeTweens ball
		Tween.get( ball ).to rotation: 0, 1

		@player_1_score.text = parseInt @player_1_score.text + 1.0

		ball.x    = @window.width()   / 2
		ball.y    = @window.height()  / 2
		ball.regX = ball.image.width  / 2
		ball.regY = ball.image.height / 2

		if @player_1_score.text is 3

			player_1_win.x = ( @window.width() / 2 ) - 100
			player_1_win.y = ( @window.height() / 2 )

			@stage.addChild player_1_win
			Tween.get( player_1_win ).to y: ( @window.height() / 2 ) - 45, 500

			@reset_game()

		
	player_two_score: =>

		Tween.removeTweens ball
		Tween.get( ball ).to rotation: 0, 1
		
		@player_2_score.text = parseInt @player_2_score.text + 1.0

		ball.x    = @window.width()   / 2
		ball.y    = @window.height()  / 2
		ball.regX = ball.image.width  / 2
		ball.regY = ball.image.height / 2

		if @player_2_score.text is 3

			player_2_win.x = ( @window.width() / 2 ) - 100
			player_2_win.y = ( @window.height() / 2 )

			@stage.addChild player_2_win
			Tween.get( player_2_win ).to y: ( @window.height() / 2 ) - 45, 500

			@reset_game()


	reset_game: ->

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
			@socket.emit 'ball_pressed'


	delay: ( time, fn, args ) ->
		
		setTimeout fn, time, args


	on_resize: ->
		
		$('body').animate scrollTop: 0, 1000


$ -> app = new App

