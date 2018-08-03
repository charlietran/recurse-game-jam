pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--grid width
gridw=10
--grid height
gridh=20
--blocksize
bsz=6
--how many tetrominos have been generated
tetroct=0


function _init()
  grid={}
  for i=1,gridh do
    grid[i]={}
    for j=1,gridw do
      grid[i][j]=0
    end
  end

  add_tetro()

  score=0
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

frame=0
function _update60()
  if game_over then
    if btnp(4) then
      _init()
    end
    return
  end

  frame+=1
  frame=frame%60

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
    grid[row] = grid[row-1]
  end
  for i=1,gridw do
    grid[1][i]=0
  end
  score += 1

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
  tetroct+=1
  --when tetroct hits 42, the last tetro that got added to the game grid
  --generates a column of blocks that reach to the top of the grid
  --printh(tetroct)
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

  print("score: "..score, 76, 6, 7)

  if game_over then
    rectfill(43,54,79,59,2)
    print("GAME OVER",44, 54, 7)
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
