express = require 'express'
app     = express()
port    = 3700

app.use express.static( __dirname + '/' )

io = require('socket.io').listen app.listen( port )

io.set('log level', 2)

# Routing
app.get '/', ( req, res ) -> res.sendfile __dirname + '/index.html'

# Variables
ball = 
	x : 240 - 15
	y : 160 - 15

player_1 = 
	x : 2
	y : 160 - 37.5

player_2 = 
	x : 480 - 25
	y : 160 - 37.5

xSpeed   = 5
ySpeed   = 5
user_num = 0
timer    = null
users    = []

io.sockets.on 'connection', ( socket ) ->

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

	socket.on 'move_1', ( percent ) -> io.sockets.emit 'paddle_1', percent
	socket.on 'move_2', ( percent ) -> io.sockets.emit 'paddle_2', percent

	socket.on 'paddlemove_1', ( page_y ) ->
		yCoord     = page_y - 40
		player_1.y = yCoord
		io.sockets.emit 'move_player_1', yCoord

	socket.on 'paddlemove_2', ( page_y ) ->
		yCoord     = page_y - 40
		player_2.y = yCoord
		io.sockets.emit 'move_player_2', yCoord

	############# P A D D L E #############


start_game = ->

	clearInterval timer
	timer = setInterval update, 20


reset = ->

	ball = 
		x : 240 - 15
		y : 160 - 15

	player_1 = 
		x : 2
		y : 160 - 37.5

	player_2 = 
		x : 480 - 25
		y : 160 - 37.5

	io.sockets.emit 'reset_game'

	clearInterval timer
	timer = null


update = ->

	ball.x = ball.x + xSpeed
	ball.y = ball.y + ySpeed

	io.sockets.emit 'ballmove', ball.x, ball.y
	
	if ball.y < 0
		ySpeed = -ySpeed
		io.sockets.emit 'wall_hit'
	
	if ball.y + 30 > 320
		ySpeed = -ySpeed
		io.sockets.emit 'wall_hit'

	if ball.x <= player_1.x + 22 and ball.x > player_1.x and ball.y >= player_1.y and ball.y < player_1.y + 75
		xSpeed *= -1
		io.sockets.emit 'paddle_hit'

	if ball.x + 30 > player_2.x and ball.x + 30 < player_2.x + 22 and ball.y >= player_2.y and ball.y < player_2.y + 75
		xSpeed *= -1
		io.sockets.emit 'paddle_hit'

	if ball.x + 30 > 480
		xSpeed = -xSpeed
		io.sockets.emit 'player_1_score'
		reset()

	if ball.x < 0
		xSpeed = -xSpeed
		io.sockets.emit 'player_2_score'
		reset()