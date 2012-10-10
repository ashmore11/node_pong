class window.App

    canvas      = null
    stage       = null
    images      = null
    xSpeed      = 12
    ySpeed      = 12
    totalLoaded = 0
    tkr         = new Object
    TitleView   = new Container()


    constructor : ->

        @TitleView = new Container()
        @tkr       = new Object

        @Main()


    document.ontouchmove = ( e ) ->

        e.preventDefault()


    Main : =>

        @canvas = document.getElementById( 'PongStage' )
        @stage  = new Stage @canvas, true

        # Touch.enable @stage, false

        @images = [ 
            { src:"img/bg.png",           id:"bg" },
            { src:"img/main.png",         id:"main" },
            { src:"img/startB.png",       id:"startB" },
            { src:"img/paddle.png",       id:"player_2" },
            { src:"img/paddle.png",       id:"player_1" },
            { src:"img/ball.png",         id:"ball" },
            { src:"img/player_1_win.png", id:"win" },
            { src:"img/player_2_win.png", id:"lose" },
        ]

        preloader = new PreloadJS()
        preloader.onFileLoad = @handleFileLoad
        preloader.loadManifest @images

        # Ticker
        Ticker.setFPS 30
        Ticker.addListener @stage

        socket = io.connect "http://scott.local:8080"

        socket.on "connect", ->
            console.log 'Connected, Frontend'

            socket.emit "adduser", prompt "What's your name?"

            socket.on "updateusers", ( data ) ->
                $.each data, ( key, value ) ->
                    console.log 'username: ' + key
                    $( '#userDiv' ).append key + ' has joined the game! <br/>'


    handleFileLoad : ( e ) =>
        # triggered when individual file comlpletes loading
        switch e.type
            when PreloadJS.IMAGE
                #image loaded
                img        = new Image()
                img.src    = e.src
                img.onload = @handleLoadComplete
                window[ e.id ] = new Bitmap( img )
                @handleLoadComplete()


    handleLoadComplete : =>

        totalLoaded++
        if @images.length is totalLoaded then @addTitleView()


    addTitleView : =>

        startB.x    = 240 - 31.5
        startB.y    = 180
        startB.name = 'startB'

        @TitleView.addChild( main, startB )
        @stage.addChild bg, @TitleView
        @stage.update()

        # Button Listeners
        startB.onPress = @tweenTitleView


    tweenTitleView : =>
        # Remove title screen
        Tween.get( @TitleView ).to( { y : -320 }, 300 ).call @addGameView


    addGameView : =>

        $( '#userDiv' ).hide()

        # Destroy Menu screen
        @stage.removeChild @TitleView
        @TitleView = null

        # Add Game View
        player_1.x = 2
        player_1.y = 160 - 37.5
        player_2.x = 480 - 25
        player_2.y = 160 - 37.5
        ball.x     = 240 - 15
        ball.y     = 160 - 15

        # Score
        @player_1_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_1_score.x = 211
        @player_1_score.y = 20

        @player_2_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_2_score.x = 262
        @player_2_score.y = 20

        @stage.addChild @player_1_score, @player_2_score, player_1, player_2, ball
        @stage.update()

        # Start Listener
        bg.onPress = @startGame


    startGame : ( e ) =>

        bg.onPress  = null
        isMouseDown = false

        document.addEventListener 'touchmove', touchFunction = ( e ) =>

            index = 0

            for touch in e.touches

                if touch.pageX < $( '#PongStage' ).width() / 2
                    @movePaddle_1( touch )
                
                if touch.pageX > $( '#PongStage' ).width() / 2
                    @movePaddle_2( touch )

                index++

        Ticker.addListener tkr, false
        tkr.tick = @update

        Tween.get( lose ).to { y : -115 }, 300
        Tween.get( win ).to { y : -115 }, 300


    movePaddle_1 : ( touch ) =>

        player_1.y = touch.pageY - 40

    movePaddle_2 : ( touch ) =>

        player_2.y = touch.pageY - 40


    reset : =>

        ball.x     = 240 - 15
        ball.y     = 160 - 15
        player_1.y = 160 - 37.5
        player_2.y = 160 - 37.5

        @stage.onMouseMove = null
        Ticker.removeListener tkr
        bg.onPress = @startGame


    resetGame : ->

        @stage.removeChild @player_1_score, @player_2_score

        # Score
        @player_1_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_1_score.x = 211
        @player_1_score.y = 20

        @player_2_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_2_score.x = 262
        @player_2_score.y = 20

        @stage.addChild @player_1_score, @player_2_score
        @stage.update()

        # Start Listener
        bg.onPress = @startGame


    alert : ( e ) =>

        Ticker.removeListener tkr
        @stage.onMouseMove = null
        bg.onPress         = @resetGame()

        if e is 'win'
            win.x = 140
            win.y = -90

            @stage.addChild win
            Tween.get( win ).to { y : 115 }, 300

        else
            lose.x = 140
            lose.y = -90

            @stage.addChild lose
            Tween.get( lose ).to { y : 115 }, 300


    update : =>
        # Ball Movement
        ball.x = ball.x + xSpeed
        ball.y = ball.y + ySpeed

        # Wall collision up
        if ball.y < 0
            ySpeed = -ySpeed

        # Wall collision down
        if ball.y + 30 > 320
            ySpeed = -ySpeed

        # Player 1 score
        if ball.x + 30 > 480
            xSpeed = -xSpeed
            @player_1_score.text = parseInt @player_1_score.text + 1
            @reset()

        # Player 2 score
        if ball.x < 0
            xSpeed = -xSpeed
            @player_2_score.text = parseInt @player_2_score.text + 1
            @reset()

        # Player 1 collision
        if ball.x <= player_1.x + 22 and ball.x > player_1.x and ball.y >= player_1.y and ball.y < player_1.y + 75
            xSpeed *= -1

        # Player 2 collision
        if ball.x + 30 > player_2.x and ball.x + 30 < player_2.x + 22 and ball.y >= player_2.y and ball.y < player_2.y + 75
            xSpeed *= -1

        # Stop paddle leaving canvas
        if player_1.y >= 249
            player_1.y = 249
        else if player_2.y >= 249
            player_2.y = 249

        # Check for player 1 win
        if @player_1_score.text is 5
            @alert 'win'

        # Check for player 2 win
        if @player_2_score.text is 5
            @alert 'lose'

