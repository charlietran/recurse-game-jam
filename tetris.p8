pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--grid width
gridw=10
--grid height
gridh=20
--blocksize
bsz=6
--how many frames have been rendered in the current step
--when this reaches 0 at the end of each step, tetro moves down
frame_step=0
--how many lines to clear to reach next level
lines_per_level=8
--level 1 step time
base_step_time=60
--how much to decrease step_time by each level
difficulty_rate=2/3
--sprite number of the ghost block
ghost_color=1

function _init()

  --grid value meanings
  --0: empty block
  --1: ghost block
  --2-8: filled block, number denotes color
  grid={}
  for i=1,gridh do
    grid[i]={}
    for j=1,gridw do
      grid[i][j]=0
    end
  end

  --how many tetrominos have been generated
  tetro_ct=0
  --how long to wait before dropping tetro one block
  step_time=base_step_time
  curr_level=1

  add_tetro()

  lines_cleared=0
  game_over=false

  --play the tetris theme(sounds terrible atm)
  --music(0)

end

--returns true if shape is overlapping with existing block/out of bounds
function collide(shape, newx, newy)
  for local_y,row in pairs(shape) do
    for local_x,value in pairs(row) do
      if value==1 then
        local abs_x = newx+local_x-1
        local abs_y = newy+local_y-1

        if (abs_x > gridw) or (abs_x < 1) then
          return true
        end
        if (abs_y > gridh) or (abs_y < 1) then
          return true
        end
        if (grid[abs_y][abs_x] > 1) then
          return true
        end
      end
    end
  end
 
  return false
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

  --buttons--
  --index: key--

  --0: left
  --1: right
  --2: up
  --3: down
  --4: z/circle
  --5: x/cross

  local active_shape=active.tetro.shapes[active.rotation]
  if btnp(1) and not collide(active_shape, active.x+1, active.y) then
    active.x+=1
  elseif btnp(0) and not collide(active_shape, active.x-1, active.y) then
    active.x-=1
  elseif btnp(3) then
    move_down(active)
  elseif btnp(5) then
    slam_tetro(active)
  end

  if btnp(2) then
    rotate_tetro(active)
  end

  --add ghost tetro
  ghost={}
  setmetatable(ghost, {__index=active})
  function ghost.color()
    return ghost_color
  end
  slam_tetro(ghost)

  if frame_step==0 then
    move_down(active)
  end

  check_lines()
end

--drop tetro as far as it will go
function slam_tetro(tet_obj)
  while move_down(tet_obj) do
  end
end

--move a tetro down one block
function move_down(tet_obj)
  local new_y=tet_obj.y+1
  if collide(tet_obj:current_shape(),tet_obj.x,new_y) then
    if tet_obj:color() ~= ghost_color then
      add_to_grid(tet_obj:current_shape(),tet_obj:color(),tet_obj.x,tet_obj.y)
      add_tetro()
    end
    return false
  else
    tet_obj.y = new_y
    return true
  end
end

--replace a line with the one above it repeatedly until the top,
--which becomes an empty row
function delete_line(line)
  for row=line,2,-1 do
    for i=1, gridw do
      grid[row][i] = grid[row-1][i]
    end
  end
  for i=1,gridw do
    grid[1][i]=0
  end
  lines_cleared += 1

  if lines_cleared%lines_per_level == 0 then
    curr_level+=1
    step_time = ceil(base_step_time * (difficulty_rate^(curr_level-1)))
  end

end

--check the grid for a filled lines and delete them
function check_lines()
  for i=1,gridh do
    local block_count=0
    for j=1,gridw do
      if grid[i][j]>ghost_color then
        block_count+=1
      end
    end
    if block_count==gridw then
      delete_line(i)
    end
  end
end

--add the active tetro to the grid
function add_to_grid(shape,color,x,y)
  for local_y, row in pairs(shape) do
    for local_x, value in pairs(row) do
      if value == 1 then
        local abs_x = x+local_x-1
        local abs_y = y+local_y-1
        grid[abs_y][abs_x] = color
      end
    end
  end
end


--generate a new tetro object(but lua doesn't really have those)
function make_tetro()
  local new_index = ceil(rnd(#tetros))
  local new_tetro={
    tetro=tetros[new_index],
    x=4,
    y=1,
    rotation=1
  }
  new_tetro.current_shape=function(self)
    return self.tetro.shapes[self.rotation]
  end

  new_tetro.color =function(self)
    return self.tetro.color
  end

  return new_tetro
end


--replace active tetro with next_tetro, generate a new next_tetro
function add_tetro()
  if not active then
    next_tetro=make_tetro()
    active=make_tetro()
  else
    active=next_tetro
    next_tetro=make_tetro()
  end

  if collide(active:current_shape(), active.x, active.y) then
    game_over=true
  end
  tetro_ct+=1
end

--rotate a tetro to to its next shape (90 degrees clockwise)
function rotate_tetro(tet_obj)
  local new_rotation=tet_obj.rotation
  if new_rotation>=#tet_obj.tetro.shapes then
    new_rotation=1
  else
    new_rotation+=1
  end

  local new_shape=tet_obj.tetro.shapes[new_rotation]

  if collide(new_shape,tet_obj.x,tet_obj.y) then
    if not collide(new_shape,tet_obj.x-1,tet_obj.y) then
      tet_obj.x-=1
    elseif not collide(new_shape,tet_obj.x-2,tet_obj.y) then
      tet_obj.x-=2
    elseif not collide(new_shape,tet_obj.x+1,tet_obj.y) then
      tet_obj.x+=1
    else
      return
    end
  end
  tet_obj.rotation=new_rotation
end

--draw a block to an absolute position on screen
function draw_block(color, x, y)
  local sprite_position=8+(color*bsz)
  sspr(sprite_position, 0, bsz, bsz, x, y)
end

--draw an entire tetro onto the grid
function draw_tetro_on_grid(tet_obj)
  local rotation=tet_obj.rotation
  local shape=tet_obj.tetro.shapes[rotation]
  for row_num,row in pairs(shape) do
    for col_num,value in pairs(row) do
      if value==1 then
        abs_x = (col_num-1+tet_obj.x)*bsz
        abs_y = (row_num-1+tet_obj.y)*bsz
        draw_block(tet_obj:color(),abs_x,abs_y)
      end
    end
  end
end

--draw a preview of the next tetro in the queue off the grid
function draw_next_tetro_preview(tet_obj)
  local next_x=80
  local next_y=34
  for row_num,row in pairs(tet_obj.tetro.shapes[1]) do
    for col_num,value in pairs(row) do
      if value==1 then
        grid_x = col_num*bsz+next_x
        grid_y = row_num*bsz+next_y
        draw_block(tet_obj:color(),grid_x,grid_y)
      end
    end
  end
end

function _draw()
  if not game_over then
    cls()
  end

  --draw the grid
  for y,row in pairs(grid) do
    for x,cell in pairs(row) do
      if cell then
        sspr(8+cell*bsz, 0, bsz, bsz, x*bsz, y*bsz)
      end
    end
  end

  draw_tetro_on_grid(active)
  draw_tetro_on_grid(ghost)
  draw_next_tetro_preview(next_tetro)

  print("lines: "..lines_cleared, 76, 6, 7)
  print("level: "..curr_level, 76, 14, 7)
  print("next piece:",76,28,7)

  local game_over_x=44
  local game_over_y=54

  if game_over then
    rectfill(game_over_x-1,game_over_y,79,59,8)
    print("game over",game_over_x, game_over_y, 7)
  end
end

-- tetro definitions 
--------------------------------

tetros={}

tetros[1]={
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
}

tetros[2]={
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
}

tetros[3]={
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
}

tetros[4]={
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
}

tetros[5]={
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
}


tetros[6]={
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
}

tetros[7]={
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
}
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

