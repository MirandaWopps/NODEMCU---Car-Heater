wificonf = {
--  ssid = "Reativos", pwd = "reativos",
  ssid = "LucasRede", pwd = "12345678",
    save = false,
    got_ip_cb = function (con)
                  print (con.IP)
                end
  }
  
  wifi.sta.config(wificonf)
  print("modo: ".. wifi.setmode(wifi.STATION))