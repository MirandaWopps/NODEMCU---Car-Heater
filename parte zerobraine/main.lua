-- O projeto usa sensor de luz durante a fase de teste para emular temperatura.
-- Quando o sensor de distância perceber a presença de alguém o aquecedor liga.
-- O PWM do led indica a temperatura.

-- Importando biblioteca MQTT para lua.
local mqtt = require("mqtt_library")
local TAM = 800
local cores = {}
local msg = "msg do love2d"
-- Lugar de desenho do carro
local x = 160
local y = 540
local temperatura = 0 -- temp desajada em'%'(OUTPUT)
local cAmbiente = 0 -- temp dentro do carro(INPUT)
local ligado = false -- liga/desliga(OUTPUT)

-- 160°C é aproximadamente 59,26% de 270°C.
-- 200°C é aproximadamente 74,07% de 270°C.

-- Essa funcao trata mensagens recebidas do Visual Code(ESP8266)
function celciusF (c)
  print("temperatura()") -- aqui por motivos de debug
  function novaMsg(c,t,m) -- cliente, topico, mensagem
    temperatura =  m; -- temperatura = mensagem enviada do ESP(Visual Code)
      print("temperatura()", t , m) -- aqui por motivos de debug
      
    if message == 10 then --
      ligado = true -- necessario p/ circulo verde
    end
  
    if message == 0 then --
      ligado = false -- necessario p/ circulo vermelho
    end  
      
    
  end
   c:on("message",novaMsg) -- 
  
end

-- Essa funcao faz algo com as mensagens que chegam
function mqttcb(topic, message)
  print("Received: " .. topic .. ": " .. message)
  if topic == "paraloveA08" then -- se topico for paraloveA08
    temperatura =  message; -- temperatura = mensagem
  end
  
  if topic == "paraloveA08BOOL" then -- se topico for paraloveA08BOOL
    if message == "1" then -- se mensagem == "1"
      ligado = 1 -- seta  achave boleana para 1
    else -- do contrario a chave e setada para 0
      ligado = 0
    end
  end

end

function love.load()
    love.window.setMode(600,400)  -- tela
    -- Definir as coordenadas da linha
    linhaX1 = 100   -- Posição inicial da linha (no eixo X)
    linhaX2 = 500   -- Posição final da linha (no eixo X)
    linhaY = 300    -- Posição Y da linha (horizontal)
    
  -- Variáveis para armazenar o valor da porcentagem
  porcentagem = 0
    
  -- Trocar XX pelo ID da etiqueta do seu NodeMCU
  mqtt_client = mqtt.client.create("139.82.100.100", 7981, mqttcb) -- cria conxao
  
  mqtt_client:connect("cliente love A08")
  
  -- Parte para escutar o VC comeÃ§ou no subscribe(jeito de ouvir)
  mqtt_client:subscribe({"paraloveA08"})--temperatura externa
  mqtt_client:subscribe({"paraloveA08BOOL"}) -- se inscreve no topico paraloveA08BOOL que lida com desliga liga do aquecedor
  print("Xa")
    
end


function love.mousepressed(x, y, button, istouch, presses)
    -- Verificar se o clique foi dentro da área da linha (no eixo Y da linha e entre X1 e X2)
    if y >= linhaY - 5 and y <= linhaY + 5 then
        if x >= linhaX1 and x <= linhaX2 then
            -- Calcular a porcentagem com base no clique (proporção da distância do clique em relação ao comprimento total da linha)
            porcentagem = ((x - linhaX1) / (linhaX2 - linhaX1)) * 100 
            mqtt_client:publish("paranodeA08", porcentagem) -- posta a porcentagem para o Visual Code
        end
    end
end

function love.draw()
  -- Escreve aquecedor no topo da UI
    love.graphics.setColor(1, 0, 0) 
    love.graphics.setFont( love.graphics.newFont(24) )
    love.graphics.print("AQUECEDOR", 220, 100)
  
    -- Desenhar a linha    
    love.graphics.setColor(1, 1, 1)  -- Cor da linha (branca)
    love.graphics.line(linhaX1, linhaY, linhaX2, linhaY)

    -- Desenhar o texto de porcentagem abaixo da linha
    love.graphics.setColor(1, 1, 1)  -- Cor do texto 
    love.graphics.print(string.format("%.0f%%", porcentagem), linhaX1 + (linhaX2 - linhaX1) * (porcentagem / 100), linhaY + 20)
    love.graphics.print("POWER:", 0,280)
    
    
    -- Parte da linha do meio(TEMPERATURA)
    love.graphics.print("Cº Ambiente:", 0,200)
    love.graphics.print(temperatura, 170,200)
    
    
    
    -- 1a linha(mode ON/OFF) Muda cor do circulo
    love.graphics.print("MODE: ", 0,160) -- Texto se tem alguem
    if ligado== 1 then
      love.graphics.setColor(0, 1, 0) -- green
      love.graphics.circle( "fill", 110, 180, 20, 50 ) -- desenha circulo
    else
      love.graphics.setColor(1, 0, 0) -- red
      love.graphics.circle( "fill", 110, 180, 20, 50 ) -- desenha circulo
    end
end




function love.update(dt)
   mqtt_client:handler()
   --love.graphics.print(temperatura, 170,200)
end

function love.quit()
  os.exit()
end