pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--grid width
gridw=10
--grid height
gridh=20
--blocksize
bsz=6

function _init()
  grid={}
  for i=1,gridh do
    grid[i]={}
    for j=1,gridw do
      grid[i][j]=1
    end
  end

  active={
    tetro=tetros[1],
    index=1,
    x=4,
    y=1,
    rotation=1
  }

  active.current_shape=function(self)
    return self.tetro.shapes[self.rotation]
  end

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
            printh("out of bounds")
            printh("newx: "..newx)
            printh("local_x: "..local_x)
            return true
          end
          if (abs_y > gridh) or (abs_y < 1) then
            return true
          end
          if (grid[abs_y][abs_x] ~= 1) then
            return true
          end
        end
      end
    end
   
    return false
end

frame=0
function _update60()
  frame+=1
  frame=frame%60

  local active_shape=active.tetro.shapes[active.rotation]
  if btnp(1) and not collide(active_shape, active.x+1, active.y) then
    active.x+=1
  elseif btnp(0) and not collide(active_shape, active.x-1, active.y) then
    active.x-=1
  elseif btnp(3) then
    move_down()
  end

  if btnp(4) then
    rotate_tetro()
  end

  -- TEMP shape switching code
  if btnp(5) then
    active.index+=1
    active.tetro=tetros[active.index]
  end


  if frame==0 then
    move_down()
  end
end

function move_down()
  local new_y=active.y+1
  if collide(active:current_shape(),active.x,new_y) then
    add_to_grid(active:current_shape(),active.x,active.y)
    select_new_active_tetro()
  else
    active.y = new_y
  end
end

function add_to_grid(shape,x,y)
  for local_y, row in pairs(shape) do
    for local_x, value in pairs(row) do
      if value == 1 then
        local abs_x = x+local_x-1
        local abs_y = y+local_y-1
        grid[abs_y][abs_x] = 0
      end
    end
  end
end

function select_new_active_tetro()
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
  cls()
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
        sspr(8, 0, bsz, bsz, (col_num-1)*bsz+active.x*bsz, (row_num-1)*bsz+active.y*bsz)
      end
    end
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
__gfx__
00000000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
