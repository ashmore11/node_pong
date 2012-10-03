class window.App

    stage       = null
    manifest    = null
    cpuSpeed    = 8
    xSpeed      = 10
    ySpeed      = 10
    totalLoaded = 0
    tkr         = new Object
    TitleView   = new Container()

    console.log 'hello!'

    # document.ontouchmove = ( e ) ->
    #     e.preventDefault()

    constructor : ->

        @stage       = {}
        @manifest    = {}
        @cpuSpeed    = {}
        @xSpeed      = {}
        @ySpeed      = {}
        @totalLoaded = {}
        @TitleView   = new Container()
        @tkr         = new Object

        @Main()


    Main : =>
        # Link canvas
        @canvas = document.getElementById( 'PongStage' )
        @stage  = new Stage @canvas

        @stage.mouseEventsEnabled = true

        @manifest = [
            { src:"img/bg.png",       id:"bg" },
            { src:"img/main.png",     id:"main" },
            { src:"img/startB.png",   id:"startB" },
            { src:"img/paddle.png",   id:"cpu" },
            { src:"img/paddle.png",   id:"player" },
            { src:"img/ball.png",     id:"ball" },
            { src:"img/win.png",      id:"win" },
            { src:"img/lose.png",     id:"lose" },
        ]

        preloader = new PreloadJS()
        preloader.onProgress = @handleProgress
        preloader.onComplete = @handleComplete
        preloader.onFileLoad = @handleFileLoad
        preloader.loadManifest @manifest

        # Ticker
        Ticker.setFPS 30
        Ticker.addListener @stage

        # document.getElementById( 'PongStage' ).ontouchstart = -> console.log 'Touch Down PongStage'
        # document.getElementById( 'PongStage' ).ontouchend   = -> console.log 'Touch Up PongStage'
        # document.getElementById( 'PongStage' ).ontouchmove  = -> console.log 'Touch Drag PongStage'


    handleProgress : ( event ) =>
        # Gets the percentage  using event.loaded


    handleComplete : ( event ) =>
        # triggered when loading is complete


    handleFileLoad : ( event ) =>
        # triggered when individual file comlpletes loading
        switch event.type
            when PreloadJS.IMAGE
                #image loaded
                img        = new Image()
                img.src    = event.src
                img.onload = @handleLoadComplete
                window[ event.id ] = new Bitmap( img )
                @handleLoadComplete()


    handleLoadComplete : ( event ) =>

        totalLoaded++
        if @manifest.length == totalLoaded
            @addTitleView()

    addTitleView : =>

        startB.x    = 240 - 31.5
        startB.y    = 180
        startB.name = 'startB'

        @TitleView.addChild( main, startB )
        @stage.addChild bg, @TitleView
        @stage.update()

        # Button Listeners
        startB.onPress   = @tweenTitleView


    tweenTitleView : =>
        # Start Game
        Tween.get( @TitleView ).to( { y : -320 }, 300 ).call @addGameView


    addGameView : =>
        # Destroy Menu screen
        @stage.removeChild @TitleView
        @TitleView = null

        # Add Game View
        player.x = 2
        player.y = 160 - 37.5
        cpu.x    = 480 - 25
        cpu.y    = 160 - 37.5
        ball.x   = 240 - 15
        ball.y   = 160 - 15

        # Score
        @playerScore   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @playerScore.x = 211
        @playerScore.y = 20

        @cpuScore   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @cpuScore.x = 262
        @cpuScore.y = 20

        @stage.addChild @playerScore, @cpuScore, player, cpu, ball
        @stage.update()

        # Start Listener
        bg.onPress = @startGame


    startGame : =>

        bg.onPress = null

        isMouseDown = false

        # # Touch Events
        # document.ontouchstart = ->
        #     isMouseDown = true

        # document.ontouchend = ->
        #     isMouseDown = false

        # document.ontouchmove = ( e ) =>
        #     console.log 'first event', e.layerY
        #     if isMouseDown
        #         @movePaddle( e )

        # @stage.ontouchstart = -> console.log 'Touch Down stage'
        # @stage.ontouchend   = -> console.log 'Touch Up stage'
        # @stage.ontouchmove  = -> console.log 'Touch Drag stage'

        # Mouse Events
        @stage.onMouseDown = -> 
            isMouseDown = true
            console.log 'mouse down'

        @stage.onMouseUp = -> 
            isMouseDown = false
            console.log 'mouse up'

        @stage.onMouseMove = ( e ) =>
            if isMouseDown
                @movePaddle( e )
                console.log 'mouse drag'

        # @stage.onMouseDown  = -> console.log 'Mouse Down stage'
        # @stage.onMouseUp    = -> console.log 'Mouse Up stage'
        # @stage.onMouseMove  = -> console.log 'Mouse Drag stage'

        Ticker.addListener tkr, false
        tkr.tick = @update

        Tween.get( lose ).to { y : -115 }, 300
        Tween.get( win ).to { y : -115 }, 300


    movePaddle : ( e ) =>

        player.y = e.stageY - 40


    reset : =>

        ball.x   = 240 - 15
        ball.y   = 160 - 15
        player.y = 160 - 37.5
        cpu.y    = 160 - 37.5

        @stage.onMouseMove = null
        Ticker.removeListener tkr
        bg.onPress = @startGame


    resetGame : ->
        @stage.removeChild @playerScore, @cpuScore

        # Score
        @playerScore   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @playerScore.x = 211
        @playerScore.y = 20

        @cpuScore   = new Text '0', 'bold 20px Arial', '#A3FF24'
        @cpuScore.x = 262
        @cpuScore.y = 20

        @stage.addChild @playerScore, @cpuScore
        @stage.update()

        # Start Listener
        bg.onPress = @startGame


    alert : ( e ) =>

        Ticker.removeListener tkr
        @stage.onMouseMove = null
        bg.onPress         = @resetGame()

        if e == 'win'
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

        # Cpu movement
        if cpu.y + 32 < ball.y - 14
            cpu.y = cpu.y + cpuSpeed
        else if cpu.y + 32 > ball.y + 14
            cpu.y = cpu.y - cpuSpeed

        # Wall collision up
        if ball.y < 0
            ySpeed = -ySpeed

        # Wall collision down
        if ball.y + 30 > 320
            ySpeed = -ySpeed

        # Cpu score
        if ball.x < 0
            xSpeed = -xSpeed
            @cpuScore.text = parseInt @cpuScore.text + 1
            @reset()

        # Player score
        if ball.x + 30 > 480
            xSpeed = -xSpeed
            @playerScore.text = parseInt @playerScore.text + 1
            @reset()

        # Cpu collision
        if ball.x + 30 > cpu.x and ball.x + 30 < cpu.x + 22 and ball.y >= cpu.y and ball.y < cpu.y + 75
            xSpeed *= -1

        # PLayer collision
        if ball.x <= player.x + 22 and ball.x > player.x and ball.y >= player.y and ball.y < player.y + 75
            xSpeed *= -1

        # Stop paddle leaving canvas
        if player.y >= 249
            player.y = 249

        # Check for win
        if @playerScore.text == 5
            @alert 'win'

        # Check for game over
        if @cpuScore.text == 5
            @alert 'lose'

        #console.log 'cpu-score: ' + @cpuScore.text, 'player-score: ' + @playerScore.text
        #console.log 'x-position: ' + ball.x, 'y-position: ' + ball.y

