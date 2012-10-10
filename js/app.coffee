# Create server
express = require( "express" )
app 	= express()
io 		= require( "socket.io" ).listen( 8080 )

# Routing
app.get "/", ( req, res ) ->
	res.sendfile __dirname + "/index.html"

usernames = {}

io.sockets.on "connection", ( socket ) ->

	console.log 'Connected, Backend'

	socket.on "adduser", ( username ) ->
		
		socket.username = username
		usernames[ username ] = username
		
		socket.emit "updatepong", "SERVER", "you have connected"
		
		io.sockets.emit "updateusers", usernames
