pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- constants
----------------------------------------
-- lua doesn't have constants, so these are
-- just globals that should not be modified

-- grid width and height
gridw=10
gridh=20

-- grid block size in pixels
bsz=6

--how many lines to clear to reach next level
lines_per_level=8

-- level 1 step time (used with frame_step)
base_step_time=60

-- how much to decrease step_time by each level (used with frame_step)
difficulty_rate=2/3

-- sprite number of the ghost block
ghost_color=1


function _init()
  -- how many frames have been rendered in the current step
  -- when this reaches 0 at the end of each step, tetro moves down
  frame_step=0

  --how many tetrominos have been generated
  tetro_ct=0

  -- animation timer for the line delete flash
  line_delete_timer=0

  pause=false

  --how long to wait before dropping tetro one block
  step_time=base_step_time
  curr_level=1

  lines_cleared=0
  game_over=false

  grid:init()
  player:init()

  --play the tetris theme
  music(
    10, -- pattern 10
    50, -- 50ms fadein
    7)  -- reserving channels 1, 2, 3 (1+2+4)
end

function _update60()
  if game_over then
    if btnp(4) then
      _init()
    end
    return
  end

  if not pause then
    frame_step+=1
    frame_step=frame_step%step_time
  end

  grid:update()
  player:update()
  ghost:update()
end

function _draw()
  -- clear the screen every frame, unless it's game over
  if not game_over then
    cls()
  end

  grid:draw()
  if line_delete_timer==0 then
    player:draw()
    ghost:draw()
  end

  if line_delete_timer>0 then
    for line in all(lines_deleted) do
      if line_delete_timer%3==0 then
        rectfill(
          bsz,line*bsz,
          gridw*bsz+4,line*bsz+4, 
          7
        )
      end
    end
  end

  print("lines: "..lines_cleared, 76, 6, 7)
  print("level: "..curr_level, 76, 14, 7)
  print("next piece:",76,28,7)

  if game_over then
    local game_over_x=44
    local game_over_y=54
    rectfill(game_over_x-1,game_over_y,79,59,8)
    print("game over",game_over_x, game_over_y, 7)
  end
end

--draw a block to an absolute position on screen
function draw_block(color, x, y)
  local sprite_position=8+(color*bsz)
  sspr(sprite_position, 0, bsz, bsz, x, y)
end

--returns true if shape is overlapping with existing block/out of bounds
function collide(shape, new_x, new_y)
  for local_y,row in pairs(shape) do
    for local_x,value in pairs(row) do
      if value==1 then
        local abs_x = new_x+local_x-1
        local abs_y = new_y+local_y-1

        if (abs_x > gridw) or (abs_x < 1) then
          return true
        end
        if (abs_y > gridh) or (abs_y < 1) then
          return true
        end
        if (grid.matrix[abs_y][abs_x] > ghost_color) then
          return true
        end
      end
    end
  end
 
  return false
end

--drop tetro as far as it will go
function slam_tetro(t)
  while move_down(t) do
  end
end

-- tries to move a tetro down one block
-- if it collides with something in the grid, adds the current
-- shape to the grid and player gets a new tetro
-- otherwise, moves the tetro down by incrementing tetro's y value
function move_down(t)
  local new_y=t.y+1
  if collide(t:current_shape(),t.x,new_y) then
    -- don't modify the grid if testing a ghost ttro
    if not t.is_ghost then
      grid:add(t:current_shape(),t.color,t.x,t.y)
      player:new_tetro()
      grid:check_lines()
    end
    return false
  else
    t.y = new_y
    return true
  end
end

-- grid object and functions
----------------------------------

-- the grid object holds the current state of the tetris game grid.
-- grid value meanings
-- 0: empty block
-- 1: ghost block
-- 2-8: filled block, number denotes color

grid={}
function grid:init()
  -- the 2d array for the data representation of the tetris grid
  self.matrix={}

  -- init the matrix as {grid.h} rows of {grid.w} length arrays of value 0
  for y=1,gridh do
    self.matrix[y]={}
    for x=1,gridw do
      self.matrix[y][x]=0
    end
  end
end

function grid:draw()
  -- the value of each grid cell is an x-offset multiple for the sprite sheet
  -- the sprite sheet contains all possible tetris blocks at coordinates (8,0)
  -- each block sprite is 6px by 6px (defined in bsz constant)
  -- so a cell value of 0 will draw the sprite at (8,0), 1 will draw (14,0), etc

  for y,row in pairs(self.matrix) do
    for x,cell in pairs(row) do
      if cell then
        sspr(8+cell*bsz, 0, bsz, bsz, x*bsz, y*bsz)
      end
    end
  end
end

function grid:update()
  if pause then
    if line_delete_timer==0 then
      pause=false
      for line in all(lines_deleted) do
        self:delete_line(line)
      end
    elseif line_delete_timer>0 then
      line_delete_timer-=1
    end
  end
end

-- draw a tetro onto the grid
function grid:draw_shape(shape,color,x,y)
  local abs_x, abs_y
  for row_num,row in pairs(shape) do
    for col_num,value in pairs(row) do
      if value==1 then
        abs_x = (col_num-1+x)*bsz
        abs_y = (row_num-1+y)*bsz
        draw_block(color,abs_x,abs_y)
      end
    end
  end
end

--check the grid for a filled lines and delete them
function grid:check_lines()
  lines_deleted={}
  for y=1,gridh do
    local block_count=0
    for x=1,gridw do
      if self.matrix[y][x]>ghost_color then
        block_count+=1
      end
    end
    if block_count==gridw then
      self:start_delete_line(y)
      sfx(2,1) -- play sfx 2 on channel 2
    end
  end
end

lines_deleted={}
function grid:start_delete_line(line)
  pause=true
  line_delete_timer=30
  add(lines_deleted,line)
end

-- replace a line with the one above it repeatedly until the top,
-- which becomes an empty row
function grid:delete_line(line)
  for row=line,2,-1 do
    for col=1, gridw do
      self.matrix[row][col] = self.matrix[row-1][col]
    end
  end
  for i=1,gridw do
    self.matrix[1][i]=0
  end
  lines_cleared += 1

  if lines_cleared%lines_per_level == 0 then
    curr_level+=1
    step_time = ceil(base_step_time * (difficulty_rate^(curr_level-1)))
  end
end

--add the active tetro to the grid
function grid:add(shape,color,x,y)
  local grid_x,grid_y
  for local_y, row in pairs(shape) do
    for local_x, value in pairs(row) do
      if value == 1 then
        local grid_x = x+local_x-1
        local grid_y = y+local_y-1
        self.matrix[grid_y][grid_x] = color
      end
    end
  end
end

-- end grid functions
----------------------------------


-- the player object
----------------------------------
player={}

function player:init()
  --{left button (0), right button(1)} time counters
  --value=0 means not pressed, gets set to >1,
  --counts down to 1, then tetro is moved left/right
  self.btn_ctrs={0,0}

  self:fill_bag()
  self.active_tetro=pop_first(self.tetro_bag)
  self.next_tetro=pop_first(self.tetro_bag)
end

--generate the next 7 tetros in random order
function player:fill_bag()
  self.tetro_bag={}
  local tmp={}
  for i=1,#tetro_library do
    add(tmp, i)
  end
  tmp=shuffle(tmp)
  for i=1,#tetro_library do
    add(self.tetro_bag,make_tetro(tmp[i]))
  end
end

function player:update()
  if(pause) return

  if frame_step==0 then
    move_down(self.active_tetro)
  end

  player:handle_input()
end

function player:draw()
  local at=self.active_tetro
  grid:draw_shape(at:current_shape(),at.color,at.x,at.y)

  self:draw_next_tetro_preview()
end

btn_init_repeat_delay=12
btn_repeat_interval=3

--take button code, and update counter based on btn(code)
function player:poll_btn(btn_i)
  --1st fire on initial keypress
  --2nd fire after $btn_init_repeat_delay frames
  --nth fires every $btn_repeat_interval frames afterward

  if btn(btn_i) then
    --button was not activated the previous frame
    if self.btn_ctrs[btn_i]==0 then
      self.btn_ctrs[btn_i]=btn_init_repeat_delay
      return true
    elseif self.btn_ctrs[btn_i]==1 then
      self.btn_ctrs[btn_i]=btn_repeat_interval
      return false
    else
      self.btn_ctrs[btn_i]-=1
      return self.btn_ctrs[btn_i]==1
    end
  else
    --button released, so set timer to 0
    self.btn_ctrs[btn_i]=0
    return false
  end
end

function player:handle_input()
  if(pause) then return end
  local active_shape=self.active_tetro:current_shape()

  --buttons--
  --index: key--

  --0: left
  --1: right
  --2: up
  --3: down
  --4: z/circle
  --5: x/cross

  local left_input=self:poll_btn(0)
  local right_input=self:poll_btn(1)
  local down_input=frame_step%3==0 and btn(3)

  if left_input and not collide(active_shape,self.active_tetro.x-1,self.active_tetro.y) then
    self.active_tetro.x-=1
  elseif right_input and not collide(active_shape,self.active_tetro.x+1,self.active_tetro.y) then
    self.active_tetro.x+=1
  elseif down_input then
    move_down(self.active_tetro)
  elseif btnp(5) then
    slam_tetro(self.active_tetro)
    sfx(1,3) -- play sfx 1 on channel 4
  end

  if btnp(2) then
    self.active_tetro:rotate()
  end
end

function player:draw_next_tetro_preview()
  local next_x=80
  local next_y=34
  local grid_x,grid_y
  for row_num,row in pairs(self.next_tetro.shapes[1]) do
    for col_num,value in pairs(row) do
      if value==1 then
        grid_x = col_num*bsz+next_x
        grid_y = row_num*bsz+next_y
        draw_block(self.next_tetro.color,grid_x,grid_y)
      end
    end
  end
end

-- replace active tetro with next_tetro, generate a new next_tetro
function player:new_tetro()
  self.active_tetro=self.next_tetro
  self.next_tetro=pop_first(self.tetro_bag)
  if #self.tetro_bag==0 then
    self:fill_bag()
  end

  -- if the new tetro is already touching something, then game's over
  if collide(self.active_tetro:current_shape(), self.active_tetro.x, self.active_tetro.y) then
    game_over=true
    sfx(0)
    music(-1,50)
  end
  tetro_ct+=1
end

-- end player functions
----------------------------------

-- the ghost tetro, which shows the player a preview at the bottom of the grid 
-- of where their tetro will go when it drops 
-- quacks like a tetro so that it can use slam_tetro() to be drawn
-- as far down as possible

ghost={is_ghost=true,color=ghost_color}
function ghost:update()
  -- copy properties of the active tetro
  self.x=player.active_tetro.x
  self.y=player.active_tetro.y

  -- move it as far down as possible
  slam_tetro(self)
end

function ghost:draw()
  grid:draw_shape(self:current_shape(),ghost_color,self.x,self.y)
end

function ghost:current_shape()
  return player.active_tetro:current_shape()
end

-- tetro object
--------------------------------
-- define a class-like object prototype for our tetros
tetro={
  -- initial grid position for a newly spawned tetro is 4,1
  x=4,
  y=1,
  name="",
  color=0,
  shapes={},
  rotation=1
}

function tetro:current_shape()
  return self.shapes[self.rotation]
end

function tetro:new(o)
  self.__index=self
  return setmetatable(o or {}, self)
end

--rotate a tetro to to its next shape (90 degrees clockwise)
function tetro:rotate()
  local new_rotation=self.rotation
  if new_rotation>=#self.shapes then
    new_rotation=1
  else
    new_rotation+=1
  end

  local new_shape=self.shapes[new_rotation]

  -- check if the new rotation collides with the grid
  -- nudge left/right if possible, otherwise don't rotate at all
  if collide(new_shape,self.x,self.y) then
    if not collide(new_shape,self.x-1,self.y) then
      self.x-=1
    elseif not collide(new_shape,self.x-2,self.y) then
      self.x-=2
    elseif not collide(new_shape,self.x+1,self.y) then
      self.x+=1
    else
      return
    end
  end
  self.rotation=new_rotation
end

-- helper functions
----------------------------------

--print a table (only works with flat/non-nested tables)
function print_table(t)
  printh('{')
  for i=1,#t do
    printh('  '..t[i]..',')
  end
  printh('}')
end

--return the first element from a table, remove it from table
function pop_first(t)
  local first=t[1]
  del(t,t[1])
  return first
end

--take a list table, return a new one with shuffled order
function shuffle(t)
  local ret={}
  for i=1,#t do
    local r=ceil(rnd(#t))
    local ti=t[r]
    add(ret, t[r])
    del(t, t[r])
  end
  return ret
end

-- end helper functions
----------------------------------

-- tetro definitions
--------------------------------

-- return a copy of a tetro from an index of the tetro_library
function make_tetro(index)
  local t={}
  setmetatable(t,{
    __index=tetro_library[index]
  })
  return t
end

-- return a copy of a random tetro
function random_tetro()
  local random_index=ceil(rnd(#tetro_library))
  return make_tetro(random_index)
end

tetro_library={}
tetro_library[1]=tetro:new({
  name="stick",
  color=2,
  shapes={
    {
      {0,1,0,0},
      {0,1,0,0},
      {0,1,0,0},
      {0,1,0,0}
    },
    {
      {0,0,0,0},
      {1,1,1,1},
      {0,0,0,0},
      {0,0,0,0}
    }
  }
})

tetro_library[2]=tetro:new({
  name="square",
  color=3,
  shapes={
    {
      {0,1,1,0},
      {0,1,1,0},
      {0,0,0,0},
      {0,0,0,0}
    }
  }
})

tetro_library[3]=tetro:new({
  name="t",
  color=4,
  shapes={
    {
      {0,1,0,0},
      {1,1,1,0},
      {0,0,0,0},
      {0,0,0,0}
    },
    {
      {0,1,0,0},
      {0,1,1,0},
      {0,1,0,0},
      {0,0,0,0}
    },
    {
      {0,0,0,0},
      {1,1,1,0},
      {0,1,0,0},
      {0,0,0,0}
    },
    {
      {0,1,0,0},
      {1,1,0,0},
      {0,1,0,0},
      {0,0,0,0}
    }
  }
})

tetro_library[4]=tetro:new({
  name="rightsnake",
  color=5,
  shapes={
    {
      {0,1,1,0},
      {1,1,0,0},
      {0,0,0,0},
      {0,0,0,0}
    },
    {
      {1,0,0,0},
      {1,1,0,0},
      {0,1,0,0},
      {0,0,0,0}
    }
  }
})

tetro_library[5]=tetro:new({
  name="leftsnake",
  color=6,
  shapes={
    {
      {1,1,0,0},
      {0,1,1,0},
      {0,0,0,0},
      {0,0,0,0}
    },
    {
      {0,1,0,0},
      {1,1,0,0},
      {1,0,0,0},
      {0,0,0,0}
    }
  }
})


tetro_library[6]=tetro:new({
  name="leftcane",
  color=7,
  shapes={
    {
      {1,1,0,0},
      {0,1,0,0},
      {0,1,0,0},
      {0,0,0,0}
    },
    {
      {0,0,1,0},
      {1,1,1,0},
      {0,0,0,0},
      {0,0,0,0}
    },
    {
      {0,1,0,0},
      {0,1,0,0},
      {0,1,1,0},
      {0,0,0,0}
    },
    {
      {0,0,0,0},
      {1,1,1,0},
      {1,0,0,0},
      {0,0,0,0}
    }
  }
})

tetro_library[7]=tetro:new({
  name="rightcane",
  color=8,
  shapes={
    {
      {0,1,1,0},
      {0,1,0,0},
      {0,1,0,0},
      {0,0,0,0}
    },
    {
      {0,0,0,0},
      {1,1,1,0},
      {0,0,1,0},
      {0,0,0,0}
    },
    {
      {0,1,0,0},
      {0,1,0,0},
      {1,1,0,0},
      {0,0,0,0}
    },
    {
      {1,0,0,0},
      {1,1,1,0},
      {0,0,0,0},
      {0,0,0,0}
    }
  }
})

__gfx__
00000000000001050501aaaa91bbbb31eeee21888821999941cccc51777761000000000000000000000000000000000000000000000000000000000000000000
00000000000001505051aaaa91bbbb31eeee21888821999941cccc51777761000000000000000000000000000000000000000000000000000000000000000000
00700700000001050501aaaa91bbbb31eeee21888821999941cccc51777761000000000000000000000000000000000000000000000000000000000000000000
00077000000001505051aaaa91bbbb31eeee21888821999941cccc51777761000000000000000000000000000000000000000000000000000000000000000000
00077000000001050501999991333331222221222221444441555551666661000000000000000000000000000000000000000000000000000000000000000000
00700700111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0105000015050110500d0500905006050030500105017000140001100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000005100021000010000101000020000400001000010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000306551a053306551a043306451a033306251a0130c0020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800001c5051c5551c55517555185551a5551a5551855517555155550050515555185551c5551c5551a55518555175551755517555185551a5551a5551c5551c5551855518555155550050515555155551a505
011800001a5051a5551a5551d55521555215551f5551d5551c5551c55500505185551c5551c5051a55518555175551750517555185551a5551a5551c5551c5551855518555155551850515555155551555515505
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003c6150210002100021003c6150210002100021003c6153c61502100021003c6150210002100021003c6150210002100021003c6150210002100021003c615021003c615021003c615021000210002100
010c00000415404154101541015404154041541015410154041540415410154101540415404154101541015409154091541515415154091540915415154151540915409154151541515409154091541515415154
010c0000081540814414154141440815408144141541414404154041441015410144041540414410154101440915409144151541514409154091441515415144091540914415154151440b1540b1440c1540c144
010c00000e1540e144021540215402144021240215402154021440212402154021441515415144111541114400154001440c1540c1540c1440c1240c1540c1440015400144071540714407154071540714407124
010c00000b1540b144171541715417144171241715417154171441712410154101541014410124141541414409154091441015410144091540914410154101440915409154091440912400000000000000000000
010c000015154151441c1541c14415154151441c1541c14415154151441c1541c14415154151441c1541c14414154141441c1541c14414154141441c1541c14414154141441c1541c14414154141441c1541c144
010c000015154151441c1541c14415154151441c1541c14415154151441c1541c14415154151441c1541c14414154141441c1541c14414154141441c1541c1440000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002875228752287522875223752237422475224752267522675226742267222475224742237422374221752217522174221722217522174224752247422875228752287422872226752267422475224742
010c00002375223752237522375223742237222475224742267522675226742267222875228752287422872224752247522474224722217522175221742217222175221752217422172200002000020000200002
010c000000000000002675226752267422672229752297422d7522d7522d7422d7222b7522b742297522974228752287522875228752287422872224752247422875228752287422872226752267422475224742
010c00002375223752237422372223752237422475224742267522675226752267222875228752287422872224752247522474224722217522175221742217222175221752217422172200000000000000000000
010c00001c7521c7521c7521c7521c7521c7421c7321c72218752187521875218752187521874218732187221a7521a7521a7521a7521a7521a7421a7321a7221775217752177521775217752177421773217722
010c00001875218752187521875218752187421873218722157521575215752157521575215742157321572214752147521475214752147521475214752147521474214742147421474214732147321472214722
010c0000187521875218752187521c7521c7421c7321c722217522175221752217522175221742217322172220752207522075220752207522074220732207221800018000180001800018000000000000000000
__music__
00 44454304
02 41424305
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 32282944
00 33282a44
00 34282b44
00 35282c44
01 32282944
00 33282a44
00 34282b44
00 35282c44
00 36282d44
00 37282e44
00 36282d44
02 38282e44
00 75424344
00 32424344
00 34424344
00 35424344
00 32424344

