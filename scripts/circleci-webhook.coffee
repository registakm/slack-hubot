# Description:
#   Circle CI Webhook
#
# Author:
#   @shokai

config =
  room: "#news"

debug = require('debug')('hubot:circleci-webhook')

module.exports = (robot) ->

  robot.router.post '/circleci-webhook', (req, res) ->
    debug 'received /circleci-webhook'

    console.error JSON.stringify req.body.payload, null, 2

    room = req.query.room or config.room
    room = "##{room}" unless /^#/.test room
    status    = req.body.payload?.status
    subject   = req.body.payload?.subject
    build_url = req.body.payload?.build_url
    unless room? and status? and subject? and build_url?
      return res.status(400).end 'bad request'

    res.end 'ok'
    header = if status is 'failed' then ':no_good:' else ':ok_hand:'
    text =
      [
        "#{header} [#{status.toUpperCase()}] #{subject}"
        build_url
      ].join '\n'
    debug text
    robot.send {room: room}, text
