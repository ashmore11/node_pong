express = require 'express'
app     = express()
port    = 3700

app.use express.static( __dirname + '/' )

io = require('socket.io').listen app.listen( port )

io.set( 'log level', 0 )

# Routing
app.get '/', ( req, res ) -> res.sendfile( __dirname + '/index.html' )

# Variables
ball = 
	x: 50
	y: 50

player_1 = 
	x : 1
	y : 50

player_2 = 
	x : 99
	y : 50

x_speed  = 1
y_speed  = 1.2
user_num = 0
timer    = null
users    = []
sockets  = []

io.sockets.on 'connection', ( socket ) =>

	socket.on 'adduser', ( user ) ->

		user_num += 1

		io.sockets.emit 'user_num', user_num

		sockets.push socket.id

		i = 0
		while i < sockets.length
			io.sockets.socket( sockets[i] ).emit 'assign_user', i
			i++

		if user_num > 2 then io.sockets.socket( socket.id ).emit 'max_users', user

		socket.set 'username', user, ->

			users.push user

			io.sockets.emit 'updateusers', user


	socket.on 'disconnect', ->

		user_num -= 1

		io.sockets.emit 'user_num', user_num

		socket.get 'username', ( err, user ) ->

			io.sockets.emit 'user_disconnect', user

			i = users.indexOf user
			if i > -1 then users.splice i, 1

			delete users[ user ]

			j = sockets.indexOf socket.id
			if j > -1 then sockets.splice j, 1

			i = 0
			while i < sockets.length
				io.sockets.socket( sockets[i] ).emit 'assign_user', i
				i++


	socket.on 'ball_pressed', ->

		start_game()

		io.sockets.emit 'game_started'


	socket.on 'remove_win', ->

		io.sockets.emit 'remove'


	socket.on 'move_1', ( percent ) ->

		player_1.y = percent
		
		io.sockets.emit 'paddle_1', percent


	socket.on 'move_2', ( percent ) ->

		player_2.y = percent

		io.sockets.emit 'paddle_2', percent


	socket.on 'single_player_mode', ( y ) ->

		player_2.y = y


	socket.on 'players_ready', ->

		io.sockets.emit 'start_game', users


start_game = ->

	clearInterval timer
	timer = setInterval update, 15


reset = ->

	ball = 
		x: 50
		y: 50

	player_1 = 
		x : 1
		y : 50

	player_2 = 
		x : 99
		y : 50

	io.sockets.emit 'reset_game'

	clearInterval timer
	timer = null


increase_speed = ( axis ) ->

	speed = Math.floor( ( axis * -1.02 ) * 100 ) / 100

	return speed


update = ->

	ball.x = ball.x + x_speed
	ball.y = ball.y + y_speed

	io.sockets.emit 'ballmove', ball.x, ball.y
	
	if ball.y <= 5
		y_speed = increase_speed y_speed
		io.sockets.emit 'wall_hit'
	
	if ball.y >= 95
		y_speed = increase_speed y_speed
		io.sockets.emit 'wall_hit'

	if ball.x > player_1.x and ball.x < player_1.x + 4 and ball.y > player_1.y - 10 and ball.y < player_1.y + 10
		x_speed = increase_speed x_speed
		io.sockets.emit 'paddle_hit'

	if ball.x < player_2.x and ball.x > player_2.x - 4 and ball.y > player_2.y - 10 and ball.y < player_2.y + 10
		x_speed = increase_speed x_speed
		io.sockets.emit 'paddle_hit'

	if ball.x > 99
		if x_speed < 0 then x_speed = 1 else x_speed = -1
		if y_speed < 0 then y_speed = 1.2 else y_speed = -1.2
		io.sockets.emit 'player_1_score'
		reset()

	if ball.x < 1
		if x_speed < 0 then x_speed = 1 else x_speed = -1
		if y_speed < 0 then y_speed = 1.2 else y_speed = -1.2
		io.sockets.emit 'player_2_score'
		reset()
