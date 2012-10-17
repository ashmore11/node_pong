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

        e.preventDefault()


    Main : =>

        socket = io.connect "http://scott.local:8080"

        socket.on "connect", () =>
            socket.emit "adduser", prompt "What's your name?"

            socket.on "updateusers", ( data ) =>

                $.each data, ( key, value ) =>
                    $( '#userDiv' ).append( key + ' has joined the game! <br/>' ).fadeOut 2000

        socket.on "user_num", ( user_num ) =>
            if user_num < 2
                console.log 'waiting...'
            else 
                console.log 'user_num: ' + user_num
                @tweenTitleView()

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
            { src:"img/player_1_win.png", id:"win" },
            { src:"img/player_2_win.png", id:"lose" }
        ]

        preloader = new PreloadJS()
        preloader.onFileLoad = @handleFileLoad
        preloader.loadManifest @images

        # Ticker.setFPS 30
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
        
        @stage.removeChild @TitleView
        @TitleView = null

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

        @stage.addChild @player_1_score, @player_2_score, player_1, player_2, ball

        ball.onPress = () => socket.emit "bg_press"

        socket.on "game_started", () => @startGame()


    startGame : ( e ) =>

        socket.on "ballmove", ( x , y ) =>
            ball.x = x
            ball.y = y

        document.addEventListener 'touchstart', ( e ) =>

            index = 0
            for touch in e.touches
                if touch.pageX < $( '#PongStage' ).width() / 2
                    @movePaddle_1( touch )
                
                if touch.pageX > $( '#PongStage' ).width() / 2
                    @movePaddle_2( touch )
                index++

        document.addEventListener 'touchmove', ( e ) =>

            index = 0
            for touch in e.touches
                if touch.pageX < $( '#PongStage' ).width() / 2
                    @movePaddle_1( touch )
                
                if touch.pageX > $( '#PongStage' ).width() / 2
                    @movePaddle_2( touch )
                index++


    movePaddle_1 : ( touch ) =>
        
        socket.emit "paddlemove_1", touch.pageY
        socket.on "move_player_1", ( pageY ) => player_1.y = pageY


    movePaddle_2 : ( touch ) =>
        
        socket.emit "paddlemove_2", touch.pageY
        socket.on "move_player_2", ( pageY ) => player_2.y = pageY


    playerOneScore : () =>

        @player_1_score.text = parseInt @player_1_score.text + 1.0

        socket.on "reset_game", () =>
            ball.onPress = () => socket.emit "bg_press"

        ball.x = 240 - 15
        ball.y = 160 - 15

        if @player_1_score.text is 3
            win.x = 140
            win.y = -90

            @stage.addChild win
            Tween.get( win ).to { y : 115 }, 300
            @resetGame()

        
    playerTwoScore : () =>
        
        @player_2_score.text = parseInt @player_2_score.text + 1.0

        socket.on "reset_game", () =>
            ball.onPress = () => socket.emit "bg_press"

        ball.x = 240 - 15
        ball.y = 160 - 15

        if @player_2_score.text is 3
            lose.x = 140
            lose.y = -90

            @stage.addChild lose
            Tween.get( lose ).to { y : 115 }, 300
            @resetGame()


    resetGame : () =>

        @stage.removeChild @player_1_score, @player_2_score

        @player_1_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_1_score.x = 211
        @player_1_score.y = 20

        @player_2_score   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @player_2_score.x = 262
        @player_2_score.y = 20

        @stage.addChild @player_1_score, @player_2_score

        win.onPress = () =>
            socket.emit "remove_win"

        socket.on "remove", () =>
            Tween.get( win ).to { y : -115 }, 300

        lose.onPress = () =>
            socket.emit "remove_win"

        socket.on "remove", () =>
            Tween.get( lose ).to { y : -115 }, 300

        ball.onPress = () => socket.emit "bg_press"




