class App

	window       : null
	socket       : null
	canvas       : null
	stage        : null
	images       : null
	title_view   : null
	total_loaded : 0

	constructor: ->

		@window = $ window

		@title_view = new Container()

		@Main()

		$( window ).on 'touchmove', ( event ) -> event.preventDefault()


	Main: ->

		# Connect to server and add usernames
		@socket = io.connect 'http://scott.local:3700'

		@socket.on 'connect', () =>
			# Prompt the user to enter their name
			@socket.emit 'adduser', prompt "What's your name?"

			@socket.on 'updateusers', ( user ) =>

				html = user + ' has joined the game!'

				$( '#userDiv' )
					.html    html 
					.fadeIn  1000 
					.delay   1000 
					.fadeOut 1000, => $( @ ).html ''

			# Display message on screen when a user disconnects
			@socket.on 'user_disconnect', ( user ) =>

				html = user + ' has disconnected...'

				$( '#disconnectDiv' )
					.html    html 
					.fadeIn  1000 
					.delay   1000 
					.fadeOut 1000, => $( @ ).html ''

		# Check for number of users and execute according function
		@socket.on 'user_num', ( user_num ) =>

			@delay 2000, => if user_num is 2 then @hide_title_view()

		# Execute player score function when message is received from the server
		@socket.on 'player_1_score', () => @player_one_score()
		@socket.on 'player_2_score', () => @player_two_score()

		@canvas = document.getElementById 'PongStage'
		@stage  = new Stage @canvas

		@stage.canvas.width  = $( window ).width()
		@stage.canvas.height = $( window ).height()

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
		# triggered when individual file comlpletes loading
		switch e.type
			when PreloadJS.IMAGE
				#image loaded
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

		@title_view.addChild wait
		@stage.addChild @title_view


	hide_title_view: =>
		
		Tween.get( @title_view ).to y: -( ( @window.height() / 2 ) + 45 ), 500
		
		@delay 500, =>
			@add_game_view()


	add_game_view: ->

		$('#PongStage').css opacity: 0
		
		# Remove the title view
		@stage.removeChild @title_view
		@title_view = null

		# Create starting positions for the stage elements
		player_1.x = 2
		player_1.y = ( @window.height() / 2 ) - 37.5

		player_2.x = @window.width() - 25
		player_2.y = ( @window.height() / 2 ) - 37.5

		ball.x = ( @window.width() / 2 ) - 15
		ball.y = ( @window.height() / 2 ) - 15

		@player_1_score   = new Text '0', 'bold 20px Arial', '#FFF'
		@player_1_score.x = ( @window.width() / 2 ) - 30
		@player_1_score.y = 20

		@player_2_score   = new Text '0', 'bold 20px Arial', '#FFF'
		@player_2_score.x = ( @window.width() / 2 ) + 15
		@player_2_score.y = 20

		# Add all the game view elements to the stage
		@stage.addChild @player_1_score, @player_2_score, player_1, player_2, ball

		$('#PongStage').animate opacity: 1, 500

		@paddle_events()
		@trigger_game()


	trigger_game: ->

		# start the game when the ball is pressed
		ball.onPress = =>
			@socket.emit 'ball_pressed'
		
		@socket.on 'game_started', =>
			@start_game()


	paddle_events: ->

		document.addEventListener 'touchstart', ( event ) =>

			for touch in event.touches

				percent = ( touch.pageY / $(window).height() ) * 100

				if touch.pageX < $( '#PongStage' ).width() / 2 then @socket.emit 'move_1', percent
				if touch.pageX > $( '#PongStage' ).width() / 2 then @socket.emit 'move_2', percent

		document.addEventListener 'touchmove', ( event ) =>

			for touch in event.touches

				percent = ( touch.pageY / $(window).height() ) * 100
			
				if touch.pageX < $( '#PongStage' ).width() / 2 then @socket.emit 'move_1', percent
				if touch.pageX > $( '#PongStage' ).width() / 2 then @socket.emit 'move_2', percent

		@socket.on 'paddle_1', ( percent ) => @move_paddle_1( percent )
		@socket.on 'paddle_2', ( percent ) => @move_paddle_2( percent )


	start_game: ->

		# receiving ball coordinates from the server
		@socket.on 'ballmove', ( x , y ) ->
			ball.x = x
			ball.y = y

		@play_audio()


	play_audio: ->

		@socket.on 'paddle_hit', -> $('#paddle_hit')[0].play()
		@socket.on 'wall_hit',   -> $('#wall_hit')[0].play()


	move_paddle_1: ( percent ) ->

		page_y = ( percent / 100 ) * $(window).height()
		
		# Send & receive the touch coordinates to/from the server
		@socket.emit 'paddlemove_1', page_y

		@socket.on 'move_player_1', ( yCoord ) ->

			player_1.y = yCoord

			height = $(window).height() - 75

			# Stop player_1 paddle from leaving the screen
			if player_1.y >= height then player_1.y = height
			if player_1.y <= 0      then player_1.y = 0


	move_paddle_2: ( percent ) ->

		page_y = ( percent / 100 ) * $(window).height()
		
		# Send & receive the touch coordinates to/from the server
		@socket.emit 'paddlemove_2', page_y

		@socket.on 'move_player_2', ( yCoord ) ->

			player_2.y = yCoord

			height = $(window).height() - 75

			# Stop player_2 paddle from leaving the screen
			if player_2.y >= height then player_2.y = height
			if player_2.y <= 0      then player_2.y = 0


	player_one_score: =>

		$('#cheer')[0].play()

		# Increment player_1 score by one
		@player_1_score.text = parseInt @player_1_score.text + 1.0

		# Only when the reset message is received from the server allow the ball press function
		@socket.on 'reset_game', =>
			ball.onPress = =>
				@socket.emit 'ball_pressed'

		# Reset ball position
		ball.x = 240 - 15
		ball.y = 160 - 15

		# Tween the win element when the user reaches 3
		if @player_1_score.text is 3
			player_1_win.x = 140
			player_1_win.y = -90

			@stage.addChild player_1_win
			Tween.get( player_1_win ).to y: 115, 300
			@reset_game()

		
	player_two_score: =>

		$('#cheer')[0].play()
		
		# Increment player_2 score by one
		@player_2_score.text = parseInt @player_2_score.text + 1.0

		# Only when the reset message is received from the server allow the ball press function
		@socket.on 'reset_game', =>
			ball.onPress = =>
				@socket.emit 'ball_pressed'

		# Reset ball position
		ball.x = 240 - 15
		ball.y = 160 - 15

		# Tween the win element when the user reaches 3
		if @player_2_score.text is 3
			player_2_win.x = 140
			player_2_win.y = -90

			@stage.addChild player_2_win
			Tween.get( player_2_win ).to y: 115, 300

			@reset_game()


	reset_game: ->

		# Reset player scores back to zero
		@stage.removeChild @player_1_score, @player_2_score

		@player_1_score   = new Text '0', 'bold 20px Arial', '#FFF'
		@player_1_score.x = ( $(window).width() / 2 ) - 30
		@player_1_score.y = 20

		@player_2_score   = new Text '0', 'bold 20px Arial', '#FFF'
		@player_2_score.x = ( $(window).width() / 2 ) + 15
		@player_2_score.y = 20

		@stage.addChild @player_1_score, @player_2_score

		# Remove the win element from the screen when pressed
		player_1_win.onPress = => @socket.emit 'remove_win'
		
		@socket.on 'remove', ->
			Tween.get( player_1_win ).to y: -115, 300

		# Remove the win element from the screen when pressed
		player_2_win.onPress = => @socket.emit 'remove_win'
		
		@socket.on 'remove', ->
			Tween.get( player_2_win ).to y: -115, 300

		ball.onPress = =>
			@socket.emit 'ball_pressed'


	delay: ( time, fn, args ) ->
		
		setTimeout fn, time, args


$ -> app = new App

