# Create server
express   = require( "express" )
app       = express()
io        = require( "socket.io" ).listen( 8080 )
usernames = {}

# Routing
app.get "/", ( req, res ) =>
    res.sendfile __dirname + "/index.html"


#                                       #
#    basic variables for application    #
#                                       #

ball = 
    x : 240 - 15
    y : 160 - 15

player_1 = 
    x : 2
    y : 160 - 37.5

player_2 = 
    x : 480 - 25
    y : 160 - 37.5

xSpeed             = 12
ySpeed             = 12
update_interval_id = null
user_num           = 0


io.sockets.on "connection", ( socket ) =>
    console.log 'Connected, Backend'

    socket.on "adduser", ( username ) =>
        socket.username       = username
        usernames[ username ] = username

        socket.emit "updatepong", "SERVER", "you have connected"
        io.sockets.emit "updateusers", usernames

        user_num++

    socket.on "paddlemove_1", ( pageY ) =>
        player_1.y = pageY
        io.sockets.emit "move_player_1", player_1.y

        if user_num < 2 then show_wait() else start_game()

    socket.on "paddlemove_2", ( pageY ) =>
        player_2.y = pageY
        io.sockets.emit "move_player_2", player_2.y


show_wait = () =>

    console.log "Waiting for another player to join!"


start_game = ( socket ) =>

    update_interval_id = setInterval update, 50

    # Ball Movement
    ball.x = ball.x + xSpeed
    ball.y = ball.y + ySpeed

    # Wall collision up
    if ball.y < 0
        ySpeed = -ySpeed

    # Wall collision down
    if ball.y + 30 > 320
        ySpeed = -ySpeed

    # Player 1 collision
    if ball.x <= player_1.x + 22 and ball.x > player_1.x and ball.y >= player_1.y and ball.y < player_1.y + 75
        xSpeed *= -1

    # Player 2 collision
    if ball.x + 30 > player_2.x and ball.x + 30 < player_2.x + 22 and ball.y >= player_2.y and ball.y < player_2.y + 75
        xSpeed *= -1

    io.sockets.emit "ballmove", ball.x, ball.y




end_game = () =>

    clearInterval update_interval_id
    update_interval_id = null


update = () =>
    
    


