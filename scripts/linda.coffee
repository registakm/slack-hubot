# Description:
#   linda
#
# Dependencies:
#   "debug": "*"
#
# Commands:
#
# Author:
#   @shokai

config =
  channel: '#news'
  space: "masuilab"  # main
  spaces :
    delta : "デルタ"  # 名前と読み仮名
    iota  : "イオタ"
    tau   : "タウ"
    shokai: "しょうかいハウス"

module.exports = (robot) ->

  robot.on 'linda:ready', ->
    robot.linda.config = config

    robot.linda.read_with_timeout = (space_name, tuple, msec, callback = ->) ->
      ts = robot.linda.tuplespace(space_name)
      cid = ts.read tuple, (err, tuple) ->
        cid = null
        callback(err, tuple)
      setTimeout ->
        if cid
          ts.cancel cid
          callback "timeout"
      , msec
