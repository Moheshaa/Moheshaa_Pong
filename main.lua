Class = require 'class'

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
-- https://github.com/Ulydev/push

push = require 'push' --CALL PUSH

require 'Paddle'


require 'Ball'


WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720


VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243


-- paddle speed; multiplied by dt in update(px/sec)
PADDLE_SPEED = 200

--Runs only once; used to initialize the game.

function love.load()

    --NEAREST-NEIGHBOUR FILTER/ PREVENT BLURRING
    love.graphics.setDefaultFilter('nearest', 'nearest') 

    -- set the title of our application window
    love.window.setTitle('Moheshaa - Pong')

    -- "seed" the RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())
    

    --change font type
    smallfont = love.graphics.newFont('font.ttf', 8)

    scorefont = love.graphics.newFont('font.ttf', 32)

    victoryfont = love.graphics.newFont('font.ttf', 24)
    -- set LÖVE2D's active font to the smallFont obect
    love.graphics.setFont(smallfont)

    --sounds
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['point_scored'] = love.audio.newSource('sounds/point_scored.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    gTextures = {
        ['Sky'] = love.graphics.newImage('Sky.png')
    }

    -- initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, 
        {
        fullscreen = false,
        resizable = true,
        vsync = true
        }
    )

    --set player score
    player1Score = 0
    player2Score = 0

    servingPlayer = math.random(2) == 1 and 1 or 2

    winningPlayer = 0

    player1 = Paddle(5, 20, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH -20 , VIRTUAL_HEIGHT- 30, 5, 20)
    ball = Ball(VIRTUAL_WIDTH/2-2, VIRTUAL_HEIGHT/2-2, 5, 5)
 
    if servingPlayer == 1 then
        ball.dx = 100
    else
        ball.dx = -100

    end

 
    -- game state variable used to transition between different parts of the game
    -- (used for beginning, menus, main game, high score list, etc.)
    -- we will use this to determine behavior during render and update
    gameState = 'start'
    
   
end



function love.resize(w, h)
    push:resize(w, h)
end


--    Runs every frame, with "dt" passed in, our delta in seconds since the last frame, which LÖVE2D supplies us.

function love.update(dt)

    -- update our ball based on its DX and DY only if we're in play state;
    -- scale the velocity by dt so movement is framerate-independent

    if gameState == 'play' then
           
        if ball.x <= 0 then 
            player2Score = player2Score + 1
            servingPlayer = 1
            sounds['point_scored']:play()

            ball:reset()
            ball.dx = 100


            if player2Score >= 5 then
                gameState = 'victory'
                winningPlayer = 2
            else
                gameState = 'serve'
            end
        end

        if ball.x >= VIRTUAL_WIDTH + 4 then 
            player1Score = player1Score + 1
            servingPlayer = 2
            sounds['point_scored']:play()
            ball:reset()
            ball.dx = -100
            if player1Score >= 5 then
                gameState = 'victory'
                winningPlayer = 1
            else
                gameState = 'serve'
            end
        end


        if ball:collides(player1) then
            --deflect ball to the right(change speed from -100 to +100)
            ball.dx = -ball.dx * 1.01
            ball.x = player1.x + 5

            sounds['paddle_hit']:play()

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

        end

        if ball:collides(player2) then
            --deflect ball to the left
            ball.dx = -ball.dx * 1.01
            ball.x = player2.x -4

            sounds['paddle_hit']:play()

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball.y <= 0 then
            --deflect ball down
            ball.dy = -ball.dy
            ball.y = 0

            sounds['wall_hit']:play()
        end   

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            --deflect ball upwards
            ball.dy = -ball.dy
            ball.y = VIRTUAL_HEIGHT - 4

            sounds['wall_hit']:play()
        end
    end


    -- player 1 movement

    if love.keyboard.isDown('w') then
        
       player1.dy = -PADDLE_SPEED

    elseif love.keyboard.isDown('s') then
       
        player1.dy = PADDLE_SPEED

    else
        player1.dy = 0
    end

    
    -- player 2 movement
    if love.keyboard.isDown('up') then
       
        player2.dy = -PADDLE_SPEED

    elseif love.keyboard.isDown('down') then
       
        player2.dy = PADDLE_SPEED

    else
        player2.dy = 0
    end

    
    if gameState == 'play' then
        ball:update(dt)
    end
    
    player1:update(dt)
    player2:update(dt)

end

--Keyboard handling

function love.keypressed(key)
    
    if key == 'escape' then
        
        love.event.quit()
    
    -- if we press enter during the start state of the game, we'll go into play mode
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'victory' then
            gameState = 'start'
            player1Score = 0
            player2Score = 0
        elseif gameState == 'serve' then
            gameState = 'play'

        end
    end
end

--used to draw anything to the screen

function love.draw()
    -- begin rendering at virtual resolution
    push:apply('start')

    --background colour(0 to 1 values i.e. floating point values in newer version of lua)
    --love.graphics.clear(40/225, 45/255, 52/255, 255/255)
    --love.graphics.draw(background, 0, 0)


    local backgroundWidth = gTextures['Sky']:getWidth()
    local backgroundHeight = gTextures['Sky']:getHeight()

    love.graphics.draw(gTextures['Sky'], 
        -- draw at coordinates 0, 0
        0, 0, 
        -- no rotation
        0,
        -- scale factors on X and Y axis so it fills the screen
        VIRTUAL_WIDTH / (backgroundWidth - 1), VIRTUAL_HEIGHT / (backgroundHeight - 1))
    
    --welcome text
    love.graphics.setFont(smallfont)

    love.graphics.setColor(40/225, 45/255, 52/255, 255/255)

    if gameState == 'start' then
        love.graphics.printf("Welcome to Pong Moheshaa!", 0, 10, VIRTUAL_WIDTH, 'center')

        love.graphics.printf("Press Enter to Play!", 0, 20, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'serve' then

        love.graphics.printf("Player " .. tostring(servingPlayer) .. "'s turn!", 0, 10, VIRTUAL_WIDTH, 'center')

        love.graphics.printf("Press Enter to serve", 0, 20, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'victory' then
        love.graphics.setFont(victoryfont)
        
        love.graphics.printf("Player " .. tostring(winningPlayer) .. " Wins!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallfont)
        love.graphics.printf("Press Enter to Play Again", 0, 42, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'play' then


    end

    --ball 
    ball:render()

    --paddles
    player1:render()
    player2:render()
    
    --fps
    displayFPS()

    --score text
    love.graphics.setColor(106/225, 90/225, 205/225, 1)
    love.graphics.setFont(scorefont)
    love.graphics.print(player1Score, VIRTUAL_WIDTH/2-50, VIRTUAL_HEIGHT/3)
    love.graphics.print(player2Score, VIRTUAL_WIDTH/2+30, VIRTUAL_HEIGHT/3)
    
    push:apply('end')
end

function displayFPS()
    love.graphics.setColor(106/225, 90/225, 205/225, 1)
    love.graphics.setFont(smallfont)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(1,1,1,1)
end

