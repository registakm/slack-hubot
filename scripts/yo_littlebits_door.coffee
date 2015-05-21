# Description:
#   Yoでドアを開ける、チャットから権限を管理できる
#
# Commands:
#   hubot ドア開けて
#   hubot [USERNAME] 鍵あげる
#   hubot [USERNAME] 鍵返して
#
# Author:
#   @shokai

request = require 'request'

## ドアを開ける関数
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

  ## ドアを開けられる権限を管理する
  Users =
    key: "yo_door_users"
    get: ->
      try JSON.parse(robot.brain.get @key) or []
      catch err then []
    set: (data) ->
      robot.brain.set @key, JSON.stringify data
    add: (name) ->
      return if @isMember name
      @set @get().concat name.toUpperCase()
    delete: (name) ->
      @set @get().filter (i) -> i isnt name
    isMember: (name) -> # 開ける権限があるかどうか返す
      return @get().indexOf(name.toUpperCase()) >= 0

  ## チャットからドアを開ける
  robot.respond /ドア開けて$/i, (msg) ->
    door_open ->
      msg.send "ドア開けました"

  robot.respond /鍵$/i, (msg) ->
    msg.send JSON.stringify Users.get()

  robot.respond /([A-Z0-9]+) 鍵あげる$/i, (msg) ->
    Users.add msg.match[1]
    msg.send "#{msg.match[1]}に鍵をあげました"

  robot.respond /([A-Z0-9]+) 鍵返して$/i, (msg) ->
    Users.delete msg.match[1]
    msg.send "#{msg.match[1]}から鍵を取り上げました"

  ## YoのWebhookを受信し、ドアを開ける
  robot.router.get '/yo/door_open', (req, res) ->
    ip = req.query.user_ip
    unless who = req.query.username
      return res.status(400).end 'invalid request'
    unless Users.isMember who
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
