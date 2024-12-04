-- MUDAR meu id!!!!
local meuid = "LUCASa08"
local m = mqtt.Client("clientid " .. meuid, 120)

-- Led numbers 
local led1 = 0
local led2 = 6
local led3 = 3 -- A porta D3 está contendo o LED usado. 

-- Determinamos que o pino sera utilizado como OUTPUT.
gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
gpio.mode(led3, gpio.OUTPUT)

-- botoes
local sw1 = 5  --btn3
local sw2 = 4 -- btn2

-- Variaveis para envio de info
local celcius = 0 -- temperatura
local ocupado = 0 -- pessoa no carro

--  PWM setup
pwm.setup(led3,500,512) -- set pin index led3 as pwm output, frequency 500Hz, duty cycle is "half"(512), the max=1023
pwm.start(led3)  -- faz led configurado iniciar
pwm.setduty(led3,0 ) -- comecar desligado

-- botoes anexados, mas leitura nao e aqui
gpio.mode(sw1, gpio.INT, gpio.PULLUP)
gpio.mode(sw2, gpio.INT, gpio.PULLUP)

-- Funcao necessaria para desligar o LED por trig
function desliga()
  pwm.setduty(led3, 0) -- "power": 0 de 1023
end

-- calcula PWM e modifica o led
function dealPercentage(c,topic,m)
  if ocupado == 1 then  -- se ocupado meche no pwm
    local porcentagem = tonumber(m) --string do mqtt p/ number
    result = (m/100)*1023 -- (m/100)= (p/1023)
    pwm.setduty(led3, result) -- atualiza o led
  end

  if ocupado == 0 then -- Se vazio
    pwm.setduty(led3, 0) -- led desligado
  end

end

-- Essa e a regra de 3 que me baseei
-- 0 X 500
-- 0 X  60celsius

-- Funcao habilitada quando nova inscricao
-- trig sw1 botao 2: printa no console do esp por debug | liga                    | posta no topico paraloveA08BOOl msg 0 com necessidade de entrega de msg(2)
-- trig sw2 botao 3: printa no console do esp por debug |desliga                  | posta no topico paraloveA08BOOl msg 1 com necessidade de entrega de msg(2)
-- c:on... quando ESP OUVIR mensagem no protocolo meeche no PWM do led 
function novaInscricao (c) 
  gpio.trig(sw1, "down", function () print("-> sw1",adc.read(0)); gpio.write(led3,0); c:publish("paraloveA08BOOL","0",2,0); ocupado=0; desliga() end) 
  gpio.trig(sw2, "down", function () print("-> sw2");             gpio.write(led3,1); c:publish("paraloveA08BOOL","1",2,0); ocupado=1; end)
  c:on("message", dealPercentage)
end

-- Funcao conectado lidando com parametro client
function conectado (client)
  -- Lugar de escrita
  client:subscribe("paranodeA08", 0, novaInscricao)
  -- parte de envio de celsius
  client:publish("paraloveA08","Node conectou " .. meuid,0,0) -- Isso surge no comeco, deixei por debugs

  function enviaTemp(client) -- 
    print("adc:", adc.read(0)) -- debuga printando temp no console. adc.read(0) e o sensor de luz, mas estamos fingindo que e temperatura.

    -- Regra de 3
    -- 500 surge porque de 1023 o 500 e quando idealizamos que esta na temperatura ideal.
    -- 60 temepratura ideal.
    -- decrescemos 1023 para ter um valor condizendo com a reducao de porcentagem.
    celcius=  (60*(1023-adc.read(0) )  )/500 
    tCelcius= tostring(celcius) -- passamos para string para enviar no mqtt
    client:publish("paraloveA08",tCelcius,0,0)  -- publicamos temperatura no topico paraloveA08, qos(necessidade de entregar msg)
                                                                                                    --e retain flag parametrizados com 0 
  end
  
  --Estamos lendo o sensor de temperatura, mas no caso estamos simulando através do de luz. 
  tmr.create():alarm(5000, tmr.ALARM_AUTO, function() enviaTemp(client) end) -- funcao que de 5s em 5s porque esta ALARM_AUTO 
                                                                                                                     -- executa a func enviaTemp passando o param da func maior
  
end 

-- conecta no IP e porta abaixo. Secury = false= sem TLS. A funcao conectado ira rodar e se der erro printara a razao.
m:connect("139.82.100.100", 7981, false, 
             conectado,
             function(client, reason) print("failed reason: "..reason) end)