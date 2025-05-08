love = require"love"


function love.load()
    love.filesystem.isFused(true)
    math.randomseed(love.math.random(),love.math.random())
    love.graphics.setNewFont("Assets/Font/Jersey10-Regular.ttf", 36)
    font = love.graphics.getFont()
    love.window.setMode(1280,720,{resizable = true})
    love.window.setTitle("Legally distinct flapping birdie pipe game")
    love.graphics.setDefaultFilter("nearest","nearest")
    title = "Legally distinct duck flapping up down pipe dodging simulator remastered GOTY edition!"
    icon = love.image.newImageData("Assets/icon.png")
    love.window.setIcon(icon)
    love.graphics.setColor(1, 1, 1, 1)
    _G.RES_X = love.graphics.getWidth()
    _G.RES_Y = love.graphics.getHeight()
    _G.global_scale = (math.min(RES_X,RES_Y))/720

    if love.filesystem.exists("savedata.save") then
        _G.saving = true
        contents = love.filesystem.read("savedata.save")
        _G.high_score = tonumber(contents)
        if high_score == nil then
            high_score = 0
        end
        success = true
        error = ""
    else
        _G.saving = false
        _G.high_score = 0
    end

    _G.sounds = {
        allofme = love.audio.newSource("Assets/all_of_me_21_savage.mp3", "stream"),
        jumpscare = love.audio.newSource("Assets/fred_fazballs_jumpscare.wav", "static")
    }

    _G.volume = {}
    volume.scale = 8 * global_scale
    volume.x = volume.scale
    volume.y = volume.scale
    volume.texture = love.graphics.newImage("Assets/volume.png")
    volume.btn_off = love.graphics.newQuad(0, 0, 16, 16, volume.texture:getDimensions())
    volume.btn_on = love.graphics.newQuad(16, 0, 16, 16, volume.texture:getDimensions())
    volume.bounds = function ()
        return {volume.x, volume.y, volume.texture:getWidth()*volume.scale/2, volume.texture:getHeight()*volume.scale}
    end
    volume.state = true -- true is enabled, false is disabled
    volume.latch = false -- used to prevent the state from getting switched every frame
    volume.cooldown = 1
    volume.updatecd = function (dt)
        volume.cooldown = volume.cooldown - dt
    end
    volume.reset_cooldown = function ()
        volume.cooldown = 1
    end
    volume.render = function ()
        if volume.state then
            love.graphics.draw(volume.texture, volume.btn_on, volume.x, volume.y,0,volume.scale, volume.scale, 0, 0)
        else
            love.graphics.draw(volume.texture, volume.btn_off, volume.x, volume.y,0,volume.scale, volume.scale, 0, 0)
        end
    end
    volume.checkpressed = function ()
        if not volume.latch then
            if love.mouse.isDown(1) then
                local x,y = love.mouse.getPosition()
                if pointinboxcollision({x,y}, volume.bounds()) then
                    volume.state = not volume.state
                    if volume.state then
                        sounds.allofme:play()
                    else
                        sounds.allofme:stop()
                    end
                    volume.latch = true
                    volume.reset_cooldown()
                    return true
                end
            elseif #love.touch.getTouches() > 0 then
                local touches = love.touch.getTouches()
                for touch_index=1,#touches do
                    local x,y = love.touch.getPosition(touches[touch_index])
                    if pointinboxcollision({x, y}, volume.bounds()) then
                        volume.state = not volume.state
                        if volume.state then
                            sounds.allofme:play()
                        else
                            sounds.allofme:stop()
                        end
                        volume.latch = true
                        volume.reset_cooldown()
                        return true
                    end
                end
            end
        elseif not (love.mouse.isDown(1) or #love.touch.getTouches() > 0) then
            volume.latch = false
            return false
        end
        return false
    end

    sounds.allofme:setLooping(true)
    unimportant = sounds.allofme:play()

    _G.jumpscare = {}
    jumpscare.texture = love.graphics.newImage("Assets/fred_fazballs.png")
    jumpscare.opacity = 1
    jumpscare.scale = {
        x = RES_X/jumpscare.texture:getWidth(),
        y = RES_Y/jumpscare.texture:getHeight()
    }
    jumpscare.enabled = false
    jumpscare.render = function ()
        love.graphics.setColor(1,1,1,jumpscare.opacity)
        love.graphics.draw(jumpscare.texture, 0, 0, 0, jumpscare.scale.x, jumpscare.scale.y)
        love.graphics.setColor(1,1,1,1)
    end
    jumpscare.progress = function (dt)
        jumpscare.opacity = jumpscare.opacity - dt
        if jumpscare.opacity < 0 then
            jumpscare.opacity = 1
            jumpscare.enabled = false
        end
    end



    _G.bullet_texture = love.graphics.newImage("Assets/bullet.png")
    _G.alt_bullet_texture = love.graphics.newImage("Assets/coca.png")
    _G.pipe_texture = love.graphics.newImage("Assets/pipe.png")
    _G.pipe_texture_ud = love.graphics.newImage("Assets/pipeud.png")
    _G.bullet_enemies_on_screen = {}
    _G.obstacle_enemies_on_screen = {}
    _G.last_time = love.timer.getTime()
    _G.other_last_time = love.timer.getTime()
    _G.this_time = love.timer.getTime()

    _G.start_game = true
    _G.up_pressed = false
    _G.score = 0

    _G.background = {
        progression = 0,
        parallax = 100,
        scale = 8 * global_scale,
        farthest = love.graphics.newImage("Assets/background/furthest.png"),
        middle = love.graphics.newImage("Assets/background/middle.png"),
        close = love.graphics.newImage("Assets/background/close.png"),
        clouds = love.graphics.newImage("Assets/background/clouds.png"),
        sky = {0.6,0.75,0.95},
        clouds_instanced = {},
        progress_clouds = function ()
            if math.random() > 0.9975 then--                XPOS[1]                 YPOS[2]                                                  SCALE[3]              SPEED[4] 
                table.insert(background.clouds_instanced, {-192*background.scale, (math.random()*background.scale*20)+(background.scale*5), (math.random()*3)+2, (math.random())+0.5})
            end
            if #background.clouds_instanced > 0 then
                for cloud=1,#background.clouds_instanced - 1 do
                    background.clouds_instanced[cloud][1] = background.clouds_instanced[cloud][1] + background.clouds_instanced[cloud][4]
                    if background.clouds_instanced[cloud][1] > (192*background.scale) then
                        table.remove(background.clouds_instanced, cloud)
                    end
                end
            end
        end,
        render = function ()
            love.graphics.draw(background.farthest,-math.fmod((background.progression * 0.02 * background.parallax), 192 * background.scale),RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)
            love.graphics.draw(background.farthest,-math.fmod((background.progression * 0.02 * background.parallax), 192 * background.scale) + 192 * background.scale,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)

            love.graphics.draw(background.middle,-math.fmod((background.progression * 0.03 * background.parallax), 192 * background.scale),RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)
            love.graphics.draw(background.middle,-math.fmod((background.progression * 0.03 * background.parallax), 192 * background.scale) + 192 * background.scale,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)

            love.graphics.draw(background.close,-math.fmod((background.progression * 0.05 * background.parallax), 192 * background.scale),RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)
            love.graphics.draw(background.close,-math.fmod((background.progression * 0.05 * background.parallax), 192 * background.scale) + 192 * background.scale,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)
            
            if #background.clouds_instanced > 0 then
                for cloud=1,#background.clouds_instanced - 1 do
                    love.graphics.draw(background.clouds,-(background.clouds_instanced[cloud][1] * 0.01 * background.parallax),background.clouds_instanced[cloud][2],0, background.clouds_instanced[cloud][3], background.clouds_instanced[cloud][3],0,0)
                end
            end
        end,
        set_sky = function ()
            love.graphics.setBackgroundColor(background.sky)
        end
    }

    _G.button = {
        texture = love.graphics.newImage("Assets/Buttons.png")
    }

    dumbass_bird_texture = love.graphics.newImage("Assets/naive_ass_dumbass_bird.png")

    _G.dumbass_bird = {
        x = RES_X/6,
        y = RES_Y/2,
        texture = dumbass_bird_texture,
        normal = love.graphics.newQuad(0, 0, 8, 5, dumbass_bird_texture:getDimensions()),
        flapping = love.graphics.newQuad(8, 0, 8, 5, dumbass_bird_texture:getDimensions()),
        scale = 8 * global_scale,
        time_unpressed = 0,
        held_last_frame = false,
        width = dumbass_bird_texture:getWidth(),
        height = dumbass_bird_texture:getHeight(),
        render = function () 
            if (love.keyboard.isDown("up") or #love.touch.getTouches() > 0 or love.mouse.isDown(1)) then
                love.graphics.draw(dumbass_bird.texture, dumbass_bird.flapping,(dumbass_bird.x)-(dumbass_bird.width/2*dumbass_bird.scale),(dumbass_bird.y)-(dumbass_bird.height/2*dumbass_bird.scale),0,dumbass_bird.scale,dumbass_bird.scale,0,0)
            else
                love.graphics.draw(dumbass_bird.texture, dumbass_bird.normal,(dumbass_bird.x)-(dumbass_bird.width/2*dumbass_bird.scale),(dumbass_bird.y)-(dumbass_bird.height/2*dumbass_bird.scale),0,dumbass_bird.scale,dumbass_bird.scale,0,0)
            end
        end,
        is_colliding = function (ox,oy,ow,oh)
            local bw = (dumbass_bird.texture:getWidth()*dumbass_bird.scale/2)
            local bh = (dumbass_bird.texture:getHeight()*dumbass_bird.scale/2)
            local btl = {dumbass_bird.x-bw,dumbass_bird.y-bh}
            local btr = {dumbass_bird.x,dumbass_bird.y-bh}
            local bbl = {dumbass_bird.x-bw,dumbass_bird.y}
            local bbr = {dumbass_bird.x,dumbass_bird.y}
            local otl = {ox,oy}
            local otr = {ox+ow,oy}
            local obl = {ox,oy+oh}
            local obr = {ox+ow,oy+oh}
            local bird_pos_table = {btl,btr,bbl,bbr}
            local other_pos_table = {otl,otr,obl,obr}


            for point_index=1,#bird_pos_table do
                local point = bird_pos_table[point_index]
                if point[1] > otl[1] and point[2] > otl[2] then
                    if point[1] < obr[1] and point[2] < obr[2] then
                        return true
                    end
                end
            end
            for point_index=1,#other_pos_table do
                local point = other_pos_table[point_index]
                if point[1] > btl[1] and point[2] > btl[2] then
                    if point[1] < bbr[1] and point[2] < bbr[2] then
                        return true
                    end
                end
            end
            return false
        end
    }
    background.set_sky()

    score_text = {}
        score_text.x = RES_X/2
        score_text.y = RES_Y/2
        score_text.speed = 250
        score_text.velo_x = score_text.speed
        score_text.velo_y = score_text.speed
        score_text.progress_anim = function (dt)
            if score_text.x > RES_X/10*9 then
                score_text.velo_x = -score_text.speed
            elseif score_text.x < 0+(RES_X/10) then
                score_text.velo_x = score_text.speed
            end
            if score_text.y > RES_Y/10*9 then
                score_text.velo_y = -score_text.speed
            elseif score_text.y < 0+(RES_Y/10) then
                score_text.velo_y = score_text.speed
            end
            score_text.x, score_text.y = score_text.x + score_text.velo_x*dt, score_text.y + score_text.velo_y*dt
        end
        score_text.render = function ()
            love.graphics.printf({{0,0,0,0.5},score}, score_text.x+5, score_text.y+5, RES_X/3, "center", math.sin(love.timer.getTime())/3, 2, 1, RES_X/6.125, font:getHeight(score)*0.5)
            love.graphics.printf(score, score_text.x, score_text.y, RES_X/3, "center", math.sin(love.timer.getTime())/3, 2, 1, RES_X/6.125, font:getHeight(score)*0.5)
        end
end


function love.resize(w, h)
    _G.RES_X = love.graphics.getWidth()
    _G.RES_Y = love.graphics.getHeight()

    jumpscare.scale = {
        x = RES_X/jumpscare.texture:getWidth(),
        y = RES_Y/jumpscare.texture:getHeight()
    }

    global_scale = (math.min(RES_X,RES_Y))/720
    volume.scale = 8 * global_scale
    dumbass_bird.scale = 8 * global_scale
    background.scale = 8 * global_scale
    for enemy_index=1,#obstacle_enemies_on_screen do
        obstacle_enemies_on_screen[enemy_index].scale = 5 * global_scale
    end
    dumbass_bird.x = RES_X/6
end






function instance_enemy(type)
    if type == 0 then --bullet enemy
        local enemy = {}
        enemy.type = 0
        enemy.texture = bullet_texture
        enemy.scale = 2 + math.random()*5--float between 2 and 5
        enemy.speed = 6 - enemy.scale -- as it becomes larger and heavier slow it down to make it fair on the player
        enemy.ypos = math.random(0-(enemy.texture:getHeight()*enemy.scale * global_scale),RES_Y)
        enemy.xpos = RES_X
        enemy.update = function (dt)
            enemy.xpos = enemy.xpos - (80*dt*enemy.speed*(RES_X/RES_Y))
            enemy.speed = enemy.speed * (1 + (0.5*dt))
        end
        enemy.render = function()
            love.graphics.draw(enemy.texture, enemy.xpos, enemy.ypos, 0, enemy.scale * global_scale, enemy.scale * global_scale)
        end
        return enemy
    elseif type == 1 then --pipe enemy
        local enemy = {}
        if math.random() > 0.5 then
            --double, empty in middle
            enemy.type = 2
            enemy.texture_top = pipe_texture_ud
            enemy.texture_bottom = pipe_texture
            enemy.scale = 5 * global_scale
            enemy.centre = math.random()*(RES_Y/3) + RES_Y/3 -- somewhere between 1/3 and 2/3 through the y axis
            enemy.range = RES_Y / 5 + (RES_Y/(5*(background.progression/1000+1)))
            enemy.ypos = (-enemy.texture_top:getHeight()*enemy.scale) + enemy.centre - enemy.range/2
            enemy.xpos = RES_X
            enemy.speed = 5 + (background.progression/250)
            enemy.bounds = {}
            enemy.bounds.top = function ()
                local x = enemy.xpos
                local y = enemy.ypos
                local w = enemy.texture_top:getWidth()*enemy.scale
                local h = enemy.texture_top:getHeight()*enemy.scale
                return x,y,w,h
            end
            enemy.bounds.bottom = function ()
                local x = enemy.xpos
                local y = enemy.ypos + enemy.texture_bottom:getHeight()*enemy.scale + enemy.range
                local w = enemy.texture_bottom:getWidth()*enemy.scale
                local h = enemy.texture_bottom:getHeight()*enemy.scale
                return x,y,w,h
            end

            enemy.update = function (dt)
                enemy.xpos = enemy.xpos - enemy.speed*dt*40*(RES_X/RES_Y)
            end
            
            enemy.render = function()
                local x,y = enemy.bounds.top()
                love.graphics.draw(enemy.texture_top, x, y, 0, enemy.scale, enemy.scale)
                local x,y = enemy.bounds.bottom()
                love.graphics.draw(enemy.texture_bottom, x, y, 0, enemy.scale, enemy.scale)
            end

            
        else--single, long and space in top or bottom
            enemy.type = 1
            if math.random() > 0.5 then
                --from the top, space on bottom
                enemy.texture = pipe_texture_ud
                enemy.scale = 5 * global_scale
                local range = RES_Y / 5 + (RES_Y/(5*(background.progression/1000+1)))
                enemy.ypos = enemy.texture:getHeight()*enemy.scale + range
                enemy.xpos = RES_X
                enemy.speed = 5 + (background.progression/250)

                enemy.bounds = function()
                    local x = enemy.xpos
                    local y = enemy.ypos
                    local w = enemy.texture:getWidth()*enemy.scale
                    local h = enemy.texture:getHeight()*enemy.scale
                    return x,y,w,h
                end

                enemy.update = function (dt)
                    enemy.xpos = enemy.xpos - enemy.speed*dt*40*(RES_X/RES_Y)
                end

                enemy.render = function()
                    local x,y = enemy.bounds()
                    love.graphics.draw(enemy.texture, x, y, 0, enemy.scale, enemy.scale)
                end
                
            else
                --from the bottom, space on top
                enemy.texture = pipe_texture
                enemy.scale = 5 * global_scale
                local range = RES_Y / 5 + (RES_Y/(5*(background.progression/1000+1)))
                enemy.ypos = range
                enemy.xpos = RES_X
                enemy.speed = 5 + (background.progression/250)

                enemy.bounds = function()
                    local x = enemy.xpos
                    local y = enemy.ypos
                    local w = enemy.texture:getWidth()*enemy.scale
                    local h = enemy.texture:getHeight()*enemy.scale
                    return x,y,w,h
                end

                enemy.update = function (dt)
                    enemy.xpos = enemy.xpos - enemy.speed*dt*40*(RES_X/RES_Y)
                end

                enemy.render = function()
                    local x,y = enemy.bounds()
                    love.graphics.draw(enemy.texture, x, y, 0, enemy.scale, enemy.scale)
                end
            end
            
        end
        table.insert(obstacle_enemies_on_screen, enemy)
    end
end

function save_score()
    savedata = love.filesystem.newFile("savedata.save")
    savedata:open("w")
    savedata:write(tostring(high_score))
    savedata:close()
end

function reset_score_for_dist()
    savedata = love.filesystem.newFile("savedata.save")
    savedata:open("w")
    savedata:write("0")
    savedata:close()
end

function pointinboxcollision(point, box)
    boxx,boxy,boxw,boxh = box[1],box[2],box[3],box[4]
    x,y = point[1],point[2]
    if x > boxx and x < boxx + boxw then
        if y > boxy and y < boxy + boxh then
            return true
        end
    end
    return false
end


function love.update(dt)
    
    --Game has started
    if not start_game then


        if (love.keyboard.isDown("up") or #love.touch.getTouches() > 0 or love.mouse.isDown(1)) and dumbass_bird.time_unpressed > -30 then
            dumbass_bird.time_unpressed = dumbass_bird.time_unpressed - 1*math.min(50,(50*math.max(10,(background.progression/1000))))*dt
        elseif not (love.keyboard.isDown("up") or #love.touch.getTouches() > 0 or love.mouse.isDown(1)) and dumbass_bird.time_unpressed < 30 then
            dumbass_bird.time_unpressed = dumbass_bird.time_unpressed + 1*math.min(50,(50*math.max(10,(background.progression/1000))))*dt
        end
        if dumbass_bird.y > RES_Y then
            dumbass_bird.y = 0
        elseif dumbass_bird.y < 0 then
            dumbass_bird.y = RES_Y
        else
            dumbass_bird.y = dumbass_bird.y + dumbass_bird.time_unpressed
        end



        background.progression = background.progression + (20 * dt)
        background.progress_clouds()
        score_text.progress_anim(dt)



        if math.random() > (1- 0.001*dt*background.progression) then
            local enemy = instance_enemy(0)
            table.insert(bullet_enemies_on_screen, enemy)
        end

        this_time = love.timer.getTime()
        if this_time - last_time > 1 then
            score = score + 10
            last_time = love.timer.getTime()
        end

        if this_time - other_last_time > 2 then
            instance_enemy(1)
            other_last_time = love.timer.getTime()
        end


        local to_remove = {}

        if #bullet_enemies_on_screen > 0 then
            for enemy_index=1,#bullet_enemies_on_screen do
                bullet_enemies_on_screen[enemy_index].update(dt)
                local enemy = bullet_enemies_on_screen[enemy_index]
                if enemy.xpos < (-enemy.texture:getWidth()*enemy.scale* global_scale)then
                    table.insert(to_remove, enemy_index)
                else
                    if dumbass_bird.is_colliding(enemy.xpos, enemy.ypos, enemy.texture:getWidth()*enemy.scale* global_scale, enemy.texture:getHeight()*enemy.scale*global_scale) then
                        if score > high_score then
                            high_score = score
                            if saving then
                                save_score()
                            end
                        end
                        last_time = love.timer.getTime()
                        score = 0
                        start_game = true
                        bullet_enemies_on_screen = {}
                        obstacle_enemies_on_screen = {}
                        dumbass_bird.x = RES_X/6
                        dumbass_bird.y = RES_Y/2
                        background.progression = 0
                        break
                    end
                end
            end
        end

        for index=1, #to_remove do
            table.remove(bullet_enemies_on_screen, to_remove[index])
            score = score + 1
        end

        local to_remove = {}

        if #obstacle_enemies_on_screen > 0 then
            for enemy_index=1,#obstacle_enemies_on_screen do
                obstacle_enemies_on_screen[enemy_index].update(dt)
                local enemy = obstacle_enemies_on_screen[enemy_index]
                if enemy.type == 1 then
                    if enemy.xpos < (-enemy.texture:getWidth()*enemy.scale)then
                        table.insert(to_remove, enemy_index)
                    else
                        if dumbass_bird.is_colliding(enemy.bounds()) then
                            if score > high_score then
                                high_score = score
                                if saving then
                                    save_score()
                                end
                            end
                            last_time = love.timer.getTime()
                            score = 0
                            start_game = true
                            bullet_enemies_on_screen = {}
                            obstacle_enemies_on_screen = {}
                            dumbass_bird.x = RES_X/6
                            dumbass_bird.y = RES_Y/2
                            background.progression = 0
                            break
                        end
                    end
                elseif enemy.type == 2 then
                    if enemy.xpos < (-enemy.texture_top:getWidth()*enemy.scale)then
                        table.insert(to_remove, enemy_index)
                    else
                        if dumbass_bird.is_colliding(enemy.bounds.top()) then
                            if score > high_score then
                                high_score = score
                                if saving then
                                    save_score()
                                end
                            end
                            last_time = love.timer.getTime()
                            score = 0
                            start_game = true
                            bullet_enemies_on_screen = {}
                            obstacle_enemies_on_screen = {}
                            dumbass_bird.x = RES_X/6
                            dumbass_bird.y = RES_Y/2
                            background.progression = 0
                            break
                        elseif dumbass_bird.is_colliding(enemy.bounds.bottom()) then
                            if score > high_score then
                                high_score = score
                                if saving then
                                    save_score()
                                end
                            end
                            last_time = love.timer.getTime()
                            score = 0
                            start_game = true
                            bullet_enemies_on_screen = {}
                            obstacle_enemies_on_screen = {}
                            dumbass_bird.x = RES_X/6
                            dumbass_bird.y = RES_Y/2
                            background.progression = 0
                            break
                        end
                    end
                end
            end
        end
        for index=1, #to_remove do
            table.remove(obstacle_enemies_on_screen, to_remove[index])
            score = score + 5
        end

        if love.math.random() > 1-(dt/180) then -- on avg every 3 min
            jumpscare.enabled = true
            unimportant = sounds.jumpscare:play()
        end
        if jumpscare.enabled then
            jumpscare.progress(dt)
        end

    --Game has ended
    else
        local been_pressed = volume.checkpressed()
        volume.updatecd(dt)

        if volume.cooldown <= 0 and not been_pressed then
            --checking that the button has not been pressed instead of anywhere else
            local touches = love.touch.getTouches()
            if not been_pressed then
                this_time = love.timer.getTime()
                if (love.keyboard.isDown("up") or #touches > 0 or love.mouse.isDown(1))and not up_pressed and (this_time - last_time > 1) then
                    up_pressed = true
                elseif not (love.keyboard.isDown("up") or #touches > 0 or love.mouse.isDown(1)) and up_pressed and (this_time - last_time > 1) then
                    start_game = false
                    up_pressed = false
                    last_time = love.timer.getTime()
                end
            end
        end
        
        

    end

end

function use_wrapped_info(input_text, input_wraplimit)
    local width, stringlist = font:getWrap(input_text, input_wraplimit)
    return width/2, font:getHeight()
end


function love.draw()
    if not start_game then
        background.render()
        if #bullet_enemies_on_screen > 0 then
            for enemy_index=1, #bullet_enemies_on_screen do
                bullet_enemies_on_screen[enemy_index].render()
            end
        end
        if #obstacle_enemies_on_screen > 0 then
            for enemy_index=1, #obstacle_enemies_on_screen do
                obstacle_enemies_on_screen[enemy_index].render()
            end
        end
        dumbass_bird.render()
        score_text.render()

        if jumpscare.enabled then
            jumpscare.render()
            
        end



    else
        love.graphics.draw(background.farthest, 0,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)

        love.graphics.draw(background.middle, 0,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)

        love.graphics.draw(background.close, 0,RES_Y - (48*background.scale),0,background.scale,background.scale,0,0)

        love.graphics.draw(background.clouds, 0,10*background.scale,0, background.scale, background.scale,0,0)

        local version = "2.2"
        love.graphics.printf({{0,0,0,0.5},version}, RES_X/2+(5*global_scale), RES_Y/4+(5*global_scale)+font:getHeight(version)/2, RES_X/4, "left", math.sin(love.timer.getTime()-0.75)/5, 15*global_scale, 15*global_scale, font:getWidth(version)/2,font:getHeight(version)/2)
        love.graphics.printf({{1,0.3,0.3},version}, RES_X/2, RES_Y/4+font:getHeight(version)/2, RES_X/4, "left", math.sin(love.timer.getTime()-0.75)/5, 15*global_scale, 15*global_scale, font:getWidth(version)/2,font:getHeight(version)/2)

        love.graphics.printf({{0,0,0,0.5},title}, RES_X/2+(5*global_scale), RES_Y/4+(5*global_scale), RES_X/4, "center", math.sin(love.timer.getTime())/5, 2*global_scale, 1*global_scale, use_wrapped_info(title, RES_X/4))
        love.graphics.printf(title, RES_X/2, RES_Y/4, RES_X/4, "center", math.sin(love.timer.getTime())/5, 2*global_scale, 1*global_scale, use_wrapped_info(title, RES_X/4))

        

        local high_score_text = string.format("Press UP arrow to start, your high score is %s", high_score)
        local formatted_high_score_text = {
            {1,1,1,1},
            "Press ",
            {1,0.3,0.3,1},
            "UP ",
            {1,1,1,1},
            "arrow to start, your high score is ",
            {1,0.3,0.3,1},
            high_score
        }

        tfwypb = {
            {1,1,1,1},
            "Time ",
            {1,0.3,0.3,1},
            "flies ",
            {1,1,1,1},
            "when you're ",
            {1,0.3,0.3,1},
            "piping birds! ",
            {1,1,1,1},
            "- William J Crumbleholme"
        }

        love.graphics.printf({{0,0,0,0.5},high_score_text}, RES_X/2+5, RES_Y/4*3+5,RES_X/3,"center", 0, 1*global_scale, 1*global_scale, use_wrapped_info(high_score_text, RES_X/4))
        love.graphics.printf(formatted_high_score_text, RES_X/2, RES_Y/4*3,RES_X/3,"center", 0, 1*global_scale, 1*global_scale, use_wrapped_info(high_score_text, RES_X/4))

        love.graphics.printf({{0,0,0,0.5},"Time flies when you're piping birds! - William J Crumbleholme"}, RES_X/16+(5*global_scale), RES_Y/8*7+(5*global_scale),RES_X/2,"center", -1/2, 1*global_scale, 1*global_scale)
        love.graphics.printf(tfwypb, RES_X/16, RES_Y/8*7,RES_X/2,"center", -1/2, 1*global_scale, 1*global_scale)

        volume.render()
    end
end