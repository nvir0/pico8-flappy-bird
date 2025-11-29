pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
// #include main.lua
SPRITES = {
    PLAYER_UP = 0,
    PLAYER_DOWN = 1,
    PLAYER_DEAD = 2
}

BUTTONS = {
    UP = 2,
    DOWN = 3,
    LEFT = 0,
    RIGHT = 1
}

WIDTH = 128
HEIGHT = 128

BOUNDARY_HEIGHT = 10

function collision(o1, o2)
    if o1.x2 > o2.x1 and o1.y2 > o2.y1 and o1.x1 < o2.x2 and o1.y1 < o2.y2 then
        return true
    end
    return false
end


function _init()
    backdrop = {
        base_color = 12
    }

    score = {
        value=0,
        x=WIDTH/2,
        y=4,
        active=true,
        color = 9,
        display = function (self)
            print(self.value, self.x, self.y, self.color)
        end,
        increment = function (self)
            if self.active then
                self.value += 1
                self.active = false
            end
        end
    }

    boundaries = {
        top = {
            x1=0, y1=0, x2=WIDTH, y2=BOUNDARY_HEIGHT
        },
        bottom = {
            x1=0, y1=HEIGHT-BOUNDARY_HEIGHT, x2=WIDTH, y2=HEIGHT
        },
        color = 4,
        draw = function (self)
            rectfill(self.top.x1, self.top.y1, self.top.x2, self.top.y2, self.color)
            rectfill(self.bottom.x1, self.bottom.y1, self.bottom.x2, self.bottom.y2, self.color)
        end
    }

    player = {
        x = 20,
        y = 20,
        dy = 0,
        alive = true,

        gravity = 0.16,
        jump_height = 2.2,


        hbx_width = 4,
        hbx_height = 6,
        
        current_sprite = SPRITES.PLAYER_DOWN,

        draw = function (self)
            spr(self.current_sprite, self.x, self.y)
        end,

        move = function (self)
            self.dy += self.gravity -- fall

            if btnp(BUTTONS.UP) and self.alive then
                self.dy -= self.jump_height -- jump
            end
            
            if not self.alive then
                self.current_sprite = SPRITES.PLAYER_DEAD
            elseif self.dy > 0 then
                self.current_sprite = SPRITES.PLAYER_DOWN
            else
                self.current_sprite = SPRITES.PLAYER_UP
            end

            self.y += self.dy
        end,

        get_hitbox = function (self)
            local hbx = {
                x1=self.x, y1=self.y, x2=self.x + self.hbx_width, y2=self.y + self.hbx_height
            }
            return hbx
        end
    }

    pipe_section = {
        x = WIDTH,
        dx = 1,
        top_y = 0,
        bottom_y = 0,
        active = false,
        width = 10,
        pipe_width = 40,
        gap_height = 32,
        color = 3,

        calculate_ys = function (self)
            if self.active then
                return
            end
            self.top_y = boundaries.top.y2 + flr(rnd(HEIGHT - BOUNDARY_HEIGHT*2 - self.gap_height))
            self.bottom_y = self.top_y + self.gap_height
            self.active = true
        end,

        move = function (self)
            if self.x < 0 - self.pipe_width then
                self.active = false
                self.x = WIDTH
            end
            self.x -= self.dx
        end,
        draw = function (self)
            rectfill(self.x, 0, self.x+self.pipe_width, self.top_y, self.color)
            rectfill(self.x, self.bottom_y, self.x+self.pipe_width, HEIGHT, self.color)
        end,
        get_hitbox_top = function (self)
            local hbx = {
                x1=self.x, y1=0, x2=self.x + self.pipe_width, y2=self.top_y
            }
            return hbx
        end,
        get_hitbox_bottom = function (self)
            local hbx = {
                x1=self.x, y1=self.bottom_y, x2=self.x + self.pipe_width, y2=HEIGHT
            }
            return hbx
        end
    }
    pipe_section:calculate_ys()
end

function _update()
    // move objects
    if player.alive then
        pipe_section:move()
        pipe_section.hitbox_top = pipe_section:get_hitbox_top()
        pipe_section.hitbox_bottom = pipe_section:get_hitbox_bottom()
    end
    player:move()
    player.hitbox = player:get_hitbox()

    if not pipe_section.active then
        pipe_section:calculate_ys()
        score.active = true
    end

    // collision checks with pipes
    if collision(player.hitbox, pipe_section.hitbox_top) then
        player.alive = false
        player.dy = 0
        
        if player.hitbox.x2 - 1 > pipe_section.x then
            player.y = pipe_section.top_y + 1 -- cap the y of ball 
        else
            player.x = pipe_section.x - player.hbx_width
        end

    elseif collision(player.hitbox, pipe_section.hitbox_bottom) then
        player.alive = false
        player.dy = 0

        if player.hitbox.x2 - 1 > pipe_section.x then
            player.y = pipe_section.bottom_y - player.hbx_height + 1 -- cap the y of ball 
        else
            player.x = pipe_section.x - player.hbx_width
        end
    end
    
    // collision checks with boundaries
    if collision(player.hitbox, boundaries.top) then
        player.alive = false
        player.dy = 0

        player.y = boundaries.top.y2 + 1


        print("COLLISION TOP")
    elseif collision(player.hitbox, boundaries.bottom) then
        print("COLLISION BOTTOM")
        player.alive = false
        player.dy = 0
        player.y = boundaries.bottom.y1 - player.hbx_height + 1 //
    end

    if player.x > pipe_section.hitbox_top.x2 + 1 then
        score:increment()
        pipe_section.dx += 0.005
        pipe_section.gap_height -= 0.1
    end
end

function _draw()
    cls(backdrop.base_color)
    boundaries:draw()
    pipe_section:draw()
    player:draw()
    score:display()

end


__gfx__
07700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000777700007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000777700007788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000077000000778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005555555555000000000000006666666666000000000000007777777777000000000000000000000000000000000000000000000000000000000000000
00000055555555555500000000000066666666666600000000000077777777777700000000000000000000000000000000000000000000000000000000000000
00000555555555555550000000000666666666666660000000000777777777777770000000000000000000000000000000000000000000000000000000000000
00005555555555555555000000006666666666666666000000007777777777777777000000000000000000000000000000000000000000000000000000000000
00055555555555555555500000066666666666666666600000077777777777777777700000000000000000000000000000000000000000000000000000000000
00555555555555555555550000666666666666666666660000777777777777777777770000000000000000000000000000000000000000000000000000000000
05555555555555555555555006666666666666666666666007777777777777777777777000000000000000000000000000000000000000000000000000000000
55555555555555555555555566666666666666666666666677777777777777777777777700000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000012120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
