pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--grid width
gridw=10
--grid height
gridh=20
--blocksize
bsz=6
--how many frames have been rendered
frame=0
--how many lines to clear to reach next level
lines_per_level=8
--level 1 step time
base_step_time=60
--how much to decrease step_time by each level
difficulty_rate=2/3

function _init()
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

end

function collide(shape, newx, newy)
      --{0,1,1,0},
      --{1,1,0,0},
      --{0,0,0,0},
      --{0,0,0,0}
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
          if (grid[abs_y][abs_x] ~= 0) then
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

  frame+=1
  frame=frame%step_time

  --Buttons--
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
    move_down()
  elseif btnp(5) then
    slam_tetro()
  end

  if btnp(2) then
    rotate_tetro()
  end

  if frame==0 then
    move_down()
  end

  check_lines()
end

function slam_tetro()
  while move_down() do
  end
end

function move_down()
  local new_y=active.y+1
  if collide(active:current_shape(),active.x,new_y) then
    add_to_grid(active:current_shape(),active.x,active.y)
    add_tetro()
    return false
  else
    active.y = new_y
    return true
  end
end

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
    --printh("level:"..curr_level.." step time "..step_time)
  end

end

function check_lines()
  for i=1,gridh do
    local block_count=0
    for j=1,gridw do
      if grid[i][j]~=0 then
        block_count+=1
      end
    end
    if block_count==gridw then
      --printh("line delete: "..i)
      delete_line(i)
    end
  end
end

function add_to_grid(shape,x,y)
  for local_y, row in pairs(shape) do
    for local_x, value in pairs(row) do
      if value == 1 then
        local abs_x = x+local_x-1
        local abs_y = y+local_y-1
        grid[abs_y][abs_x] = 1
      end
    end
  end
end



function add_tetro()
  local new_index = ceil(rnd(#tetros))
  active={
    tetro=tetros[new_index],
    x=4,
    y=1,
    rotation=1
  }

  active.current_shape=function(self)
    return self.tetro.shapes[self.rotation]
  end

  if collide(active:current_shape(), active.x, active.y) then
    game_over= true
  end
  tetro_ct+=1
end

function rotate_tetro()
  local new_rotation=active.rotation
  if new_rotation>=#active.tetro.shapes then
    new_rotation=1
  else
    new_rotation+=1
  end

  local new_shape=active.tetro.shapes[new_rotation]

  if collide(new_shape,active.x,active.y) then
    if not collide(new_shape,active.x-1,active.y) then
      active.x-=1
    elseif not collide(new_shape,active.x-2,active.y) then
      active.x-=2
    elseif not collide(new_shape,active.x+1,active.y) then
      active.x+=1
    else
      return
    end
  end
  active.rotation=new_rotation
end

function _draw()
  if not game_over then
    cls()
  end

  for y,row in pairs(grid) do
    for x,cell in pairs(row) do
      if cell then
        sspr(8+cell*bsz, 0, bsz, bsz, x*bsz, y*bsz)
      end
    end
  end

  -- draw active tetro
  local rotation=active.rotation

  local shape_to_draw=active.tetro.shapes[rotation]
  for row_num,row in pairs(shape_to_draw) do
    for col_num,value in pairs(row) do
      if value==1 then
        sspr(14, 0, bsz, bsz, (col_num-1)*bsz+active.x*bsz, (row_num-1)*bsz+active.y*bsz)
      end
    end
  end

  print("lines: "..lines_cleared, 76, 6, 7)
  print("level: "..curr_level, 76, 14, 7)

  local game_over_x=44
  local game_over_y=54

  if game_over then
    rectfill(game_over_x-1,game_over_y,79,59,8)
    print("GAME OVER",game_over_x, game_over_y, 7)
  end
end

-- TETRO DEFINITIONS 
--------------------------------

tetros={}

tetros[1]={
  name="stick",
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
00000000000001777761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001777761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000001777761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000001777761000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000001666661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

