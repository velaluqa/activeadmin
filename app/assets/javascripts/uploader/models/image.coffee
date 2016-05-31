@ImageUploader ?= {}
@ImageUploader.Models ?= {}
class ImageUploader.Models.Image extends Backbone.Model
  url: '/v1/images.json'

  defaults:
    state: 'parsing'
    warnings: null
    sopInstanceUid: null
    seriesInstanceUid: null
    seriesNumber: null
    seriesDescription: null
    contentDate: null
    acquisitionDate: null
    patient:
      id: null
      name: null
      birthDate: null
      sex: null
      age: null
      institutionName: null

  parse: (file) ->
    @file = file

    reader = new FileReader()
    reader.onload = =>
      arrayBuffer = reader.result
      byteArray = new Uint8Array(arrayBuffer)
      kb = byteArray.length / 1024
      mb = kb / 1024
      byteStr = if mb > 1 then "#{mb.toFixed(3)} MB" else "#{kb.toFixed(0)} KB"

      @set fileSize: byteStr

      dataSet = null
      try
        start = new Date().getTime()
        dataSet = dicomParser.parseDicom(byteArray)
        end = new Date().getTime()
        if dataSet.warnings.length > 0
          @set(warnings: dataSet.warnings)
        else
          @set(warnings: 'No pixeldata') unless dataSet.elements.x7fe00010
        @set
          state: 'parsed'
          parseTime: (end - start)
          sopInstanceUid: dataSet.string('x00080018')
          seriesInstanceUid: dataSet.string('x0020000e')
          seriesDescription: dataSet.string('x0008103e')
          seriesNumber: dataSet.string('x00200011')
          seriesDateTime: @parseDateTime(dataSet.string('x00080021'), dataSet.string('x00080031'), dataSet.string('x00080201'))
          acquisitionDateTime: @parseDateTime(dataSet.string('x00080022'), dataSet.string('x00080032'), dataSet.string('x00080201'))
          contentDate: @parseDateTime(dataSet.string('x00080023'), dataSet.string('x00080033'), dataSet.string('x00080201'))
          patient:
            name: dataSet.string('x00100010')
            id: dataSet.string('x00100020')
            birthDate: dataSet.string('x00100030')
            sex: dataSet.string('x00100040')
      catch error
        @set
          state: 'error'
          warnings: error

    reader.readAsArrayBuffer(file)

  parseDateTime: (date, time, timeZone) ->
    year = parseInt(date[0..3], 10)
    month = parseInt(date[4..5], 10) - 1
    day = parseInt(date[6..7], 10)
    hours = parseInt(time[0..1], 10)
    minutes = parseInt(time[2..3], 10)
    seconds = parseInt(time[4..5], 10)
    milliseconds = parseInt(time[7..9].paddingRight('000'), 10)
    new Date(Date.UTC(year, month, day, hours, minutes, seconds, milliseconds))

  @parse: (file) ->
    image = new ImageUploader.Models.Image
    image.parse(file)

  upload: ->
    formData = new FormData()
    formData.append('image[image_series_id]', @series.get('id'))
    formData.append('image[file][name]', @get('fileName'))
    formData.append('image[file][data]', @file)
    $.ajax
      type: 'POST'
      url: '/v1/images.json'
      data: formData
      beforeSend: =>
        @set state: 'uploading'
      success: =>
        @set state: 'uploaded'
      error: =>
        @set state: 'upload failed'
      cache: false
      processData: false
      contentType: false
