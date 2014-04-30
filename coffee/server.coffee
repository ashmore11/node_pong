express = require 'express'
app     = express()
port    = 3700

app.use express.static( __dirname + '/' )

io = require('socket.io').listen app.listen( port )

io.set('log level', 0)

# Routing
app.get '/', ( req, res ) -> res.sendfile __dirname + '/index.html'

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

xSpeed   = 0.5
ySpeed   = 0.7
user_num = 0
timer    = null
users    = []

io.sockets.on 'connection', ( socket ) =>

	socket.on 'adduser', ( user ) ->

		user_num += 1

		io.sockets.emit 'user_num', user_num

		socket.set 'username', user, ->

			users[ user ] = user

			io.sockets.emit 'updateusers', user


	socket.on 'disconnect', ->

		user_num -= 1

		io.sockets.emit 'user_num', user_num

		socket.get 'username', ( err, user ) ->

			delete users[ user ]

			io.sockets.emit 'user_disconnect', user


	socket.on 'ball_pressed', ->

		start_game()

		io.sockets.emit 'game_started'


	socket.on 'remove_win', ->

		io.sockets.emit 'remove'


	############# P A D D L E #############

	socket.on 'move_1', ( percent ) ->

		io.sockets.emit 'paddle_1', percent


	socket.on 'move_2', ( percent ) ->

		io.sockets.emit 'paddle_2', percent


	socket.on 'paddle_move_1', ( percent ) ->

		player_1.y = percent

		io.sockets.emit 'move_player_1', percent


	socket.on 'paddle_move_2', ( percent ) ->

		player_2.y = percent

		io.sockets.emit 'move_player_2', percent

	############# P A D D L E #############


start_game = ->

	clearInterval timer
	timer = setInterval update, 25


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


update = ->

	ball.x = ball.x + xSpeed
	ball.y = ball.y + ySpeed

	io.sockets.emit 'ballmove', ball.x, ball.y
	
	if ball.y <= 0
		ySpeed = -ySpeed
		io.sockets.emit 'wall_hit'
	
	if ball.y >= 95
		ySpeed = -ySpeed
		io.sockets.emit 'wall_hit'

	if ball.x is player_1.x + 0.5 and ball.y > player_1.y - 10 and ball.y < player_1.y + 10
		xSpeed = -xSpeed
		io.sockets.emit 'paddle_hit'

	if ball.x is player_2.x - 3.5 and ball.y > player_2.y - 10 and ball.y < player_2.y + 10
		xSpeed = -xSpeed
		io.sockets.emit 'paddle_hit'

	if ball.x > 99
		xSpeed = -xSpeed
		io.sockets.emit 'player_1_score'
		reset()

	if ball.x < 1
		xSpeed = -xSpeed
		io.sockets.emit 'player_2_score'
		reset()
