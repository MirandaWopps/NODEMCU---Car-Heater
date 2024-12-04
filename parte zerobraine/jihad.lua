local mqtt = require("mqtt_library")
local TAM = 800
local cores = {}
local msg = "msg do love2d"
-- Lugar de desenho do carro
local x = 160
local y = 540


local function (xPos)
  local x = xPos;
  
  local dr = function()
    while true do 
      love.graphics.setColor(1,1,1)
      enemyImage = love.graphics.newImage("enemy.png")
      love.graphics.draw(enemyImage,x, -50)
      coroutine.yield()
    end
  end
   
   
  return {
    draw = coroutine.wrap(dr),
    
    update = function(dt)
    end,
  }
end



function goRight()
    x = x +50
end

function goLeft()
    x = x -50
end

function move(c)
  print("move()")
    function novaMsg(c,t,m)
        print("novaMsg()",t,m)
        if m=="10" then
          goLeft();
        else
          goRight();
        end
    end
    c:on("message",novaMsg)
end

local botoes = {}
-- BOTOES
cores[1] = {
  {1,0,0},
  {0.6, 0, 0}
}
cores[2] = {
  {0.5,1,0},
  {0.35,0.4,0.2}
}

function mqttcb(topic, message)
  print("Received: " .. topic .. ": " .. message)
  local m = message     
  if m=="10" then
    goLeft();
  else
    goRight();
  end
end



  --[[
local function mqttcb (msg)
  print(msg)
end]]
-- Desenho
function love.load ()
  car = love.graphics.newImage("car2.png")
  love.window.setMode(TAM,TAM)
  love.graphics.setBackgroundColor(0,0,0)

  for i = 1, 2 do
    botoes[i] = {cores = cores[i][1], x = i*TAM/3, y = TAM/2, r = TAM/8}
  end

  mqtt_client = mqtt.client.create("139.82.100.100", 7981, mqttcb)
  -- Trocar XX pelo ID da etiqueta do seu NodeMCU
  mqtt_client:connect("cliente love A16")
  --mqtt_client:subscribe({"paraloveA16"}) -- por que chaves?
  
  -- Parte para escutar o VC comeÃ§ou no subscribe
  mqtt_client:subscribe({"paraloveA16"},0,move)
end

local function nodisco (botao, mx, my)
  return math.sqrt((mx-botao.x)^2 + (my-botao.y)^2) < botao.r
end

local function mudaestado (i)
  if botoes[i].cores == cores[i][1] then
    botoes[i].cores = cores[i][2]
  else
    botoes[i].cores = cores[i][1]
  end
end

function love.mousepressed (mx, my)
  for i = 1, 2 do
    if nodisco (botoes[i], mx, my) then
      print ("no disco ", i)
      -- Trocar XX pelo ID da etiqueta do seu NodeMCU
      mqtt_client:publish("paranodeA16", i)
      mudaestado(i)
    end
  end
end

--function mudaEstado()

function love.update(dt)
  -- tem que chamar o handler aqui!
  mqtt_client:handler()
end

function love.draw ()

  love.graphics.setColor(1,1,1)
  love.graphics.draw( car, x, y) 


end

function love.quit()
  os.exit()
end