pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
  grid={}
  for i=1,20 do
    grid[i]={}
    for j=1,10 do
      grid[i][j]=1
    end
  end


  tetros={}
  tetros[1]={
    name="line",
    index=1,
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

  active={
    tetro=tetros[1],
    x=4,
    y=1,
    rotation=1
  }
end

function _update60()
  if btnp(1) then
    active.x+=1
  elseif btnp(0) then
    active.x-=1
  end

  if btnp(4) then
    rotate_tetro()
  end
end

function add_block()
end

function rotate_tetro()
  if active.rotation>=#active.tetro.shapes then
    active.rotation=1
  else
    active.rotation+=1
  end
end

function _draw()
  cls()
  for y,row in pairs(grid) do
    for x,cell in pairs(row) do
      if cell then
        sspr(8+cell*6, 0, 6, 6, x*6, y*6)
      end
    end
  end

  -- draw active tetro
  local rotation=active.rotation

  local shape_to_draw=active.tetro.shapes[rotation]
  for row_num,row in pairs(shape_to_draw) do
    for col_num,value in pairs(row) do
      if value==1 then
        sspr(8, 0, 6, 6, (col_num-1)*6+active.x*6, (row_num-1)*6+active.y*6)
      end
    end
  end

end

__gfx__
00000000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777771000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
