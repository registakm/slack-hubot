# Yoでドアを開ける

request = require 'request'

yo_users = ['SHOKAI', 'user1', 'user2']  # Yo許可するユーザー

door_open = (callback = ->) ->
  request
    method: 'POST'
    url: "https://api-http.littlebitscloud.cc/devices/#{process.env.LB_DEVICE}/output"
    headers:
      Authorization: "Bearer #{process.env.LB_TOKEN}"
      Accept: 'application/vnd.littlebits.v2+json'
    postData:
      percent: 100
      duration_ms: 2000
  , callback

module.exports = (robot) ->

  robot.respond /ドア開けて$/i, (msg) ->
    door_open ->
      msg.send "ドア開けました"

  robot.respond /([A-Z0-9]+) 鍵あげる$/i, (msg) ->
    who = msg.match[1]
    yo_users.push who
    msg.send "#{who}に鍵をあげました"

  robot.router.get '/yo/door_open', (req, res) ->
    ip = req.query.user_ip
    unless who = req.query.username
      return res.status(400).end 'invalid request'
    if yo_users.indexOf(who.toUpperCase()) < 0
      robot.send {room: "#test"}
      , "不正なユーザー#{who}(#{ip})がYoしました"
      return res.status(400).end "bad user: #{who}"

    if req.query.token isnt process.env.YO_DOOR_TOKEN
      robot.send {room: "#test"}
      , "不正なtoken #{req.query.token}でYoが来ました"
      return res.status(400).end "bad token"

    res.end 'ok'
    door_open ->
      robot.send {room: "#test"}
      , "#{who}がYoでドアを開けました"
