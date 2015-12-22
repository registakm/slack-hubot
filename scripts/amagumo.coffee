# Description:
#   yhoo雨雲レーダーapiから雨雲の情報を取得
#
# Commands:
#   hubot amagumo
#   hubot amagumo <area>
# Author:
#   @registakm


# async = require 'async'
_ = require 'lodash'
cronJob = require('cron').CronJob
Promise = require 'bluebird'
quiche = require 'quiche'

config =
  AMAGUMO_API_URL: "http://weather.olp.yahooapis.jp/v1/place"
  GEOCODE_API_URL: "http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder"
  APP_ID: "dj0zaiZpPWdBSnhkNTNTZEdWSCZzPWNvbnN1bWVyc2VjcmV0Jng9Mjk-"
  CRON_TIME: "*/10 9-21 * * 1-5",
  # sfcの緯度・経度
  CORDINATES: "139.427367,35.388184"
  # 何分後の降雨情報を通知するか 約30分後
  NOTIFY_ARRAY_NUM: 3
  # 降水量の閾値
  AMAGUMO_THRESHOLD: "0.5"



module.exports = (robot) ->

  job = new cronJob(
    cronTime: config.CRON_TIME
    onTick: ->
      checkAmagumo robot, false, false, false
      return
    start: true
    timeZone: "Asia/Tokyo"
  )

  robot.brain.set 'amagumo', false

  robot.hear /^(雨雲|amagumo)$/i, (msg) ->
    checkAmagumo robot, true, false, false

  robot.hear /^(雨雲|amagumo) (.+)/i, (msg) ->
    area = msg.match[2]
    getAreaGeocode robot, area
    .then (result) ->
      coordinates = result.Feature[0].Geometry.Coordinates
      checkAmagumo robot, true, coordinates, area
    .catch (err) ->
      msg.send "#{area}の情報を取得できませんでした。"

checkAmagumo = (robot, notify, geocode, area) ->
  robot.http(config.AMAGUMO_API_URL)
  .query({
    appid: config.APP_ID
    coordinates: geocode or config.CORDINATES
    output: "json"
    })
  .get() (err, res, body) ->
    data = JSON.parse body
    if err or not data.Feature
      robot.logger.error err or "#{data.Error.Message}"
      return
    # Data is like below
    #
    #   "Feature": [
    # {
    #   "Id": "201512201605_139.73229_35.663613",
    #   "Name": "地点(139.73229,35.663613)の2015年12月20日 16時05分から60分間の天気情報",
    #   "Geometry": {
    #     "Type": "point",
    #     "Coordinates": "139.73229,35.663613"
    #   },
    #   "Property": {
    #     "WeatherAreaCode": 4410,
    #     "WeatherList": {
    #       "Weather": [
    #         {
    #           "Type": "observation",
    #           "Date": "201512201605",
    #           "Rainfall": 0
    #         }, ....
    else
      amagumoArray = data.Feature[0].Property.WeatherList.Weather
      showAmagumoResult robot, amagumoArray, notify, area


showAmagumoResult = (robot, dataArray, notify, area) ->
  # 通知フラグ
  send_flag = false

  head_message = if area then area + '降雨情報\n' else 'sfc降雨情報\n'

  # cron用雨が降っている時
  if dataArray[config.NOTIFY_ARRAY_NUM].Rainfall < config.AMAGUMO_THRESHOLD and (robot.brain.get 'amagumo')
    send_flag = true
    message = (getTimeString dataArray[config.NOTIFY_ARRAY_NUM].Date) + "頃、雨は止んでいるでしょう。"
  # cron用雨が降っていない時
  else if dataArray[config.NOTIFY_ARRAY_NUM].Rainfall >= config.AMAGUMO_THRESHOLD and not (robot.brain.get 'amagumo')
    send_flag = true
    message = (getTimeString dataArray[config.NOTIFY_ARRAY_NUM].Date) + "頃、" + dataArray[config.NOTIFY_ARRAY_NUM].Rainfall + "mm/hの雨が近づいています。"
  # hubot amagumo用雨が降っている時
  else if notify and dataArray[config.NOTIFY_ARRAY_NUM].Rainfall >= config.AMAGUMO_THRESHOLD and (robot.brain.get 'amagumo')
    send_flag = true
    message = (getTimeString dataArray[config.NOTIFY_ARRAY_NUM].Date) + "頃、" + dataArray[config.NOTIFY_ARRAY_NUM].Rainfall + "mm/hの雨が降るでしょう。"
  # hubot amagumo用雨が降っていない時
  else if notify and dataArray[config.NOTIFY_ARRAY_NUM].Rainfall < config.AMAGUMO_THRESHOLD and not (robot.brain.get 'amagumo')
    send_flag = true
    message = (getTimeString dataArray[config.NOTIFY_ARRAY_NUM].Date) + "頃、雨の心配はないでしょう。"

  if dataArray[config.NOTIFY_ARRAY_NUM].Rainfall >= config.AMAGUMO_THRESHOLD and not area
    robot.brain.set 'amagumo', true
  else
    robot.brain.set 'amagumo', false

  if send_flag
    barChart = new quiche 'bar'
    barChart.setWidth 480
    barChart.setHeight 200
    barChart.setBarWidth 600
    barChart.setBarSpacing 10
    barChart.addAxisLabels 'x', setDataArray dataArray, 'Date'
    barChart.addData (setDataArray dataArray, 'Rainfall'), '降水量(mm/h)', "FFFFFF"
    barChart.setAutoScaling()
    barChart.setLegendBottom()
    barChart.setTransparentBackground()

    bar_image_url = barChart.getUrl true
    bar_image_url += setChartColorParam(dataArray)
    robot.send {room: "news"}, head_message + message + bar_image_url

setDataArray = (dataArray, value) ->
  if value == 'Date'
    result = _.map dataArray, (item) ->
      getTimeString item.Date
  else
    result = _.pluck dataArray, value

getAreaGeocode = (robot, area) ->
  return new Promise (resolve, reject) ->
    robot.http(config.GEOCODE_API_URL)
    .query({
      appid: config.APP_ID
      query: area
      results: 1
      output: "json"
      })
      .get() (err, res, body) ->
        data = JSON.parse body
        if err or data.Error
          robot.logger.error err or "#{data.Error.Message}"
          reject err
        else
          resolve data

getTimeString = (str) ->
  hour = str.slice(-4, -2)
  min = str.slice(-2)

  "#{hour}:#{min}"

setChartColorParam = (dataArray) ->
  colorArray = _.map dataArray, (item) ->
    if 0.1 < item.Rainfall <= 12
      "80D8FF"
    else if 12 < item.Rainfall <= 32
      "64FFDA"
    else if 32 < item.Rainfall <= 56
      "FFD740"
    else if 56 < item.Rainfall
      "FF6E40"
    else
      "FFFFFF"
  color_param = colorArray.join(",").replace(/,/g,"|")
  "&chco=#{color_param}"
