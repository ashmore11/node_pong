class window.App

    canvas      = null
    stage       = null
    images      = null
    totalLoaded = 0
    TitleView   = new Container()
    socket      = null


    constructor : ->

        @TitleView = new Container()
        @Main()


    document.ontouchmove = ( e ) ->
        # Prevent annoying scroll
        e.preventDefault()


    Main : =>

        # Connect to server and add usernames
        socket = io.connect "http://scott.local:8080"

        socket.on "connect", () ->
            # Prompt the user to enter their name
            socket.emit "adduser", prompt "What's your name?"

            socket.on "updateusers", ( data ) ->

                # Display message on screen when a user connects
                $.each data, ( value ) ->
                    $( '#userDiv' ).html( '' )
                    $( '#userDiv' ).append( value + ' has joined the game! <br/>' )

                # Display message on screen when a user disconnects
                socket.on "user_disconnect", ( value ) ->
                    $.each data, ( value ) ->
                        $( '#disconnectDiv' ).html( '' )
                        $( '#disconnectDiv' ).append( value + ' has disconnected...' ).delay( 2000 ).fadeOut( 2000 )

        # Check for number of users and execute according function
        socket.on "user_num", ( user_num ) =>
            if user_num < 2 then @addTitleView else @tweenTitleView()

        # Execute player score function when message is received from the server
        socket.on "player_1_score", () => @playerOneScore()
        socket.on "player_2_score", () => @playerTwoScore()

        @canvas = document.getElementById 'PongStage'
        @stage  = new Stage @canvas

        @images = [
            { src:"img/waiting.gif",      id:"wait" },
            { src:"img/main.png",         id:"main" },
            { src:"img/bg.png",           id:"bg" },
            { src:"img/paddle.png",       id:"player_1" },
            { src:"img/paddle.png",       id:"player_2" },
            { src:"img/ball.png",         id:"ball" },
            { src:"img/player_1_win.png", id:"player_1_win" },
            { src:"img/player_2_win.png", id:"player_2_win" }
        ]

        preloader = new PreloadJS()
        preloader.onFileLoad = @handleFileLoad
        preloader.loadManifest @images

        Ticker.setFPS 25
        Ticker.addListener @stage


    handleFileLoad : ( e ) =>
        # triggered when individual file comlpletes loading
        switch e.type
            when PreloadJS.IMAGE
                #image loaded
                img        = new Image()
                img.src    = e.src
                img.onload = @handleLoadComplete
                window[ e.id ] = new Bitmap img
                @handleLoadComplete()


    handleLoadComplete : =>

        totalLoaded++
        if @images.length is totalLoaded then @addTitleView()


    addTitleView : =>

        wait.x = 100
        wait.y = 180

        Tween.get( wait ).to { y : 130 }, 500

        @TitleView.addChild main, wait
        @stage.addChild bg, @TitleView


    tweenTitleView : =>
        
        Tween.get( @TitleView ).to( { y : -320 }, 500 ).call @addGameView


    addGameView : =>

        # Fade out the userDiv when the gameView is added
        $( '#userDiv' ).delay( 500 ).fadeOut( 1500 )
        
        # Remove the title view
        @stage.removeChild @TitleView
        @TitleView = null

        # Create starting positions for the stage elements
        player_1.x = 2
        player_1.y = 160 - 37.5
        player_2.x = 480 - 25
        player_2.y = 160 - 37.5
        ball.x     = 240 - 15
        ball.y     = 160 - 15

        @player_1_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_1_score.x = 211
        @player_1_score.y = 20

        @player_2_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_2_score.x = 262
        @player_2_score.y = 20


        ################ P A D D L E ################

        document.addEventListener 'touchstart', ( touch ) ->

            for touch in touch.touches
                if touch.pageX < $( '#PongStage' ).width() / 2 then socket.emit "move_1", touch.pageY
                if touch.pageX > $( '#PongStage' ).width() / 2 then socket.emit "move_2", touch.pageY

        document.addEventListener 'touchmove', ( touch ) ->

            for touch in touch.touches
                if touch.pageX < $( '#PongStage' ).width() / 2 then socket.emit "move_1", touch.pageY
                if touch.pageX > $( '#PongStage' ).width() / 2 then socket.emit "move_2", touch.pageY


        socket.on "paddle_1", ( pageY ) => @movePaddle_1( pageY )
        socket.on "paddle_2", ( pageY ) => @movePaddle_2( pageY )

        ################ P A D D L E ################

        # Add all the game view elements to the stage
        @stage.addChild @player_1_score, @player_2_score, player_1, player_2, ball

        # start the game when the ball is pressed
        ball.onPress = -> socket.emit "bg_press"
        socket.on "game_started", => @startGame()


    startGame : =>

        # receiving ball coordinates from the server
        socket.on "ballmove", ( x , y ) ->
            ball.x = x
            ball.y = y


    movePaddle_1 : ( pageY ) =>
        
        # Send & receive the touch coordinates to/from the server
        socket.emit "paddlemove_1", pageY
        socket.on "move_player_1", ( yCoord ) ->
            player_1.y = yCoord

            # Stop player_1 paddle from leaving the screen
            if player_1.y >= 245 then player_1.y = 245
            if player_1.y <= 0   then player_1.y = 0


    movePaddle_2 : ( pageY ) =>
        
        # Send & receive the touch coordinates to/from the server
        socket.emit "paddlemove_2", pageY
        socket.on "move_player_2", ( yCoord ) ->
            player_2.y = yCoord

            # Stop player_2 paddle from leaving the screen
            if player_2.y >= 245 then player_2.y = 245
            if player_2.y <= 0   then player_2.y = 0


    playerOneScore : =>

        # Increment player_1 score by one
        @player_1_score.text = parseInt @player_1_score.text + 1.0

        # Only when the reset message is received from the server allow the ball press function
        socket.on "reset_game", ->
            ball.onPress = -> socket.emit "bg_press"

        # Reset ball position
        ball.x = 240 - 15
        ball.y = 160 - 15

        # Tween the win element when the user reaches 3
        if @player_1_score.text is 3
            player_1_win.x = 140
            player_1_win.y = -90

            @stage.addChild player_1_win
            Tween.get( player_1_win ).to { y : 115 }, 300
            @resetGame()

        
    playerTwoScore : =>
        
        # Increment player_2 score by one
        @player_2_score.text = parseInt @player_2_score.text + 1.0

        # Only when the reset message is received from the server allow the ball press function
        socket.on "reset_game", ->
            ball.onPress = -> socket.emit "bg_press"

        # Reset ball position
        ball.x = 240 - 15
        ball.y = 160 - 15

        # Tween the win element when the user reaches 3
        if @player_2_score.text is 3
            player_2_win.x = 140
            player_2_win.y = -90

            @stage.addChild player_2_win
            Tween.get( player_2_win ).to { y : 115 }, 300
            @resetGame()


    resetGame : =>

        # Reset player scores back to zero
        @stage.removeChild @player_1_score, @player_2_score

        @player_1_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_1_score.x = 211
        @player_1_score.y = 20

        @player_2_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_2_score.x = 262
        @player_2_score.y = 20

        @stage.addChild @player_1_score, @player_2_score

        # Remove the win element from the screen when pressed
        player_1_win.onPress = -> socket.emit "remove_win"
        socket.on "remove", -> Tween.get( player_1_win ).to { y : -115 }, 300

        # Remove the win element from the screen when pressed
        player_2_win.onPress = -> socket.emit "remove_win"
        socket.on "remove", -> Tween.get( player_2_win ).to { y : -115 }, 300

        ball.onPress = -> socket.emit "bg_press"




