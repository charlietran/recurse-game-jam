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

  --how long to wait before dropping tetro one block
  step_time=base_step_time
  curr_level=1

  lines_cleared=0
  game_over=false

  grid:init()
  player:init()

  --play the tetris theme(sounds terrible atm)
  --music(0)
end

function _update60()
  if game_over then
    if btnp(4) then
      _init()
    end
    return
  end

  frame_step+=1
  frame_step=frame_step%step_time

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
  player:draw()
  ghost:draw()

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
  self:check_lines()
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
  for y=1,gridh do
    local block_count=0
    for x=1,gridw do
      if self.matrix[y][x]>ghost_color then
        block_count+=1
      end
    end
    if block_count==gridw then
      self:delete_line(y)
    end
  end
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
  self.active_tetro=random_tetro()
  self.next_tetro=random_tetro()
end

function player:update()
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

function player:handle_input()
  local active_shape=self.active_tetro:current_shape()

  --buttons--
  --index: key--

  --0: left
  --1: right
  --2: up
  --3: down
  --4: z/circle
  --5: x/cross
  if btnp(1) and not collide(active_shape, self.active_tetro.x+1, self.active_tetro.y) then
    self.active_tetro.x+=1
  elseif btnp(0) and not collide(active_shape, self.active_tetro.x-1, self.active_tetro.y) then
    self.active_tetro.x-=1
  elseif btnp(3) then
    move_down(self.active_tetro)
  elseif btnp(5) then
    slam_tetro(self.active_tetro)
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
  self.next_tetro=random_tetro()

  -- if the new tetro is already touching something, then game's over
  if collide(self.active_tetro:current_shape(), self.active_tetro.x, self.active_tetro.y) then
    game_over=true
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

-- tetro definitions
--------------------------------

-- return a copy of a random tetro
function random_tetro()
  local t={}
  local random_index=ceil(rnd(#tetro_library))
  setmetatable(t,{
    __index=tetro_library[random_index]
  })
  return t
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
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000002000040000500000000020000400005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c0000e00010000110000c0000e0001000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c5001c5501c55017550185501a5501a5501855017550155500050015550185501c5501c5501a55018550175501755017550185501a5501a5501c5501c5501855018550155500050015550155501a500
001000001a5001a5501a5501d55021550215501f5501d5501c5501c55000500185501c5501c5001a55018550175501750017550185501a5501a5501c5501c5501855018550155501850015550155501555015500
__music__
00 44454304
02 41424305

