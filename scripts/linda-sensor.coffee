# Description:
#   lindaでセンサー値を読む
#
# Commands:
#   hubot linda 温度
#
#   hubot linda 明るさ
#
# Author:
#   @shokai


module.exports = (robot) ->

  robot.on 'linda:ready', ->

    robot.respond /([a-z0-9_\-]+) 温度/i, (msg) ->
      space_name = msg.match[1]
      robot.linda.read_with_timeout space_name, {type: "sensor", name: "temperature"}, 3000, (err, tuple) ->
        if err
          msg.send "#{space_name}の温度 わからん度"
          return
        tempe = Math.floor tuple.data.value
        msg.send "#{space_name}の温度 #{tempe}度"

    robot.respond /([a-z0-9_\-]+) 明るさ/i, (msg) ->
      space_name = msg.match[1]
      robot.linda.read_with_timeout space_name, {type: "sensor", name: "light"}, 3000, (err, tuple) ->
        if err
          msg.send "#{space_name}の明るさ 不明"
          return
        light = Math.floor tuple.data.value
        msg.send "#{space_name}の明るさ #{light}"
