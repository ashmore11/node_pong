express = require "express"
app     = express()
port    = 3700

app.use express.static( __dirname + '/public' )

io = require('socket.io').listen app.listen( port )

# io.set('log level', 2)

usernames = {}

# Routing
app.get "/", ( req, res ) -> res.sendfile __dirname + "/index.html"

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

io.sockets.on "connection", ( socket ) ->
	socket.on "adduser", ( username ) ->
		socket.username       = username
		usernames[ username ] = username

		io.sockets.emit "updateusers", usernames

		user_num++
		io.sockets.emit "user_num", user_num

	socket.on "bg_press", ->
		start_game()
		io.sockets.emit "game_started"


	############# P A D D L E #############

	socket.on "move_1", ( pageY ) -> io.sockets.emit "paddle_1", pageY
	socket.on "move_2", ( pageY ) -> io.sockets.emit "paddle_2", pageY

	socket.on "paddlemove_1", ( pageY ) ->
		yCoord     = pageY - 40
		player_1.y = yCoord
		io.sockets.emit "move_player_1", yCoord

	socket.on "paddlemove_2", ( pageY ) ->
		yCoord     = pageY - 40
		player_2.y = yCoord
		io.sockets.emit "move_player_2", yCoord

	############# P A D D L E #############


	socket.on "remove_win", -> io.sockets.emit "remove"

	socket.on "disconnect", ->
		delete usernames[ socket.username ]
		io.sockets.emit "user_disconnect"


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

	io.sockets.emit "reset_game"

	clearInterval timer
	timer = null


update = ->

	ball.x = ball.x + xSpeed
	ball.y = ball.y + ySpeed

	io.sockets.emit "ballmove", ball.x, ball.y
	
	if ball.y < 0 then ySpeed = -ySpeed
	if ball.y + 30 > 320 then ySpeed = -ySpeed

	if ball.x <= player_1.x + 22 and ball.x > player_1.x and ball.y >= player_1.y and ball.y < player_1.y + 75 then xSpeed *= -1
	if ball.x + 30 > player_2.x and ball.x + 30 < player_2.x + 22 and ball.y >= player_2.y and ball.y < player_2.y + 75 then xSpeed *= -1

	if ball.x + 30 > 480
		xSpeed = -xSpeed
		io.sockets.emit "player_1_score"
		reset()

	if ball.x < 0
		xSpeed = -xSpeed
		io.sockets.emit "player_2_score"
		reset()