@ImageUploader ?= {}
@ImageUploader.Models ?= {}
nonAllowedMimeTypes = [
  'application/zip',
  'application/gzip'
  'application/rar'
  'application/x-tar'
  'application/vnd.rar'
  'application/x-7z-compressed'
]
nonAllowedExtensions = [
  'rar'
  '7z'
  'tar'
  'gz'
]

class ImageUploader.Models.Image extends Backbone.Model
  dateTimeTags:
    seriesDate:
      date: 'x00080021'
      time: 'x00080031'
    acquisitionDate:
      date: 'x00080022'
      time: 'x00080032'
    contentDate:
      date: 'x00080023'
      time: 'x00080033'
    timezone: 'x00080201'

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

  initialize: ->
    @warnings = {}


  isDicom: (byteArray) =>
    sub = ""
    sub += String.fromCharCode(byteArray[i]) for i in [128...132]
    sub == "DICM"

  parse: (file) ->
    @file = file

    console.log(file)

    fileExtension = _.last(file.name.split("."))
    isAllowed =
      if _.includes(nonAllowedMimeTypes, file.type) or _.includes(nonAllowedExtensions, fileExtension)
        false
      else
        true

    reader = new FileReader()
    reader.onload = =>
      arrayBuffer = reader.result
      byteArray = new Uint8Array(arrayBuffer)
      kb = byteArray.length / 1024
      mb = kb / 1024
      byteStr = if mb > 1 then "#{mb.toFixed(3)} MB" else "#{kb.toFixed(0)} KB"
      @set fileSize: byteStr

      if @isDicom(byteArray)
        dataSet = null
        try
          start = new Date().getTime()
          dataSet = dicomParser.parseDicom(byteArray)
          end = new Date().getTime()

          if dataSet.warnings.length > 0
            @pushWarnings('parsing', dataSet.warnings)
          else
            @pushWarnings('parsing', ['No DICOM pixeldata']) unless dataSet.elements.x7fe00010
          @set
            state: 'parsed'
            parseTime: (end - start)
            sopInstanceUid: dataSet.string('x00080018')
            seriesInstanceUid: dataSet.string('x0020000e')
            seriesDescription: dataSet.string('x0008103e')
            seriesNumber: dataSet.string('x00200011')
            seriesDateTime: @parseDateTime(dataSet, 'seriesDate', warnIfMissing: false)
            acquisitionDateTime: @parseDateTime(dataSet, 'acquisitionDate')
            contentDateTime: @parseDateTime(dataSet, 'contentDate')
            patient:
              name: dataSet.string('x00100010')
              id: dataSet.string('x00100020')
              birthDate: dataSet.string('x00100030')
              sex: dataSet.string('x00100040')
        catch error
          console.log error
          @set
            state: 'parsing failed'
            warnings: error
      else
        if isAllowed
          @set
            state: 'parsed'
            seriesDescription: file.name
            contentDateTime: file.lastModifiedDate
        else
          @set
            state: 'parsing failed'
            seriesDescription: file.name
            contentDateTime: file.lastModifiedDate
            warnings: "File type not allowed"

    reader.readAsArrayBuffer(file)

  parseDateTime: (dataSet, tag, op = { warnIfMissing: true }) ->
    date = dataSet.string(@dateTimeTags[tag].date)
    time = dataSet.string(@dateTimeTags[tag].time)
    timezone = dataSet.string(@dateTimeTags.timezone)

    unless date?
      if op.warnIfMissing
        @pushWarnings('parsing', ["Missing date part for `#{tag}`"])
      return

    year = parseInt(date[0..3], 10)
    month = parseInt(date[4..5], 10) - 1
    day = parseInt(date[6..7], 10)

    if time?
      hours = parseInt(time[0..1], 10)
      minutes = parseInt(time[2..3], 10)
      seconds = parseInt(time[4..5], 10)
      milliseconds = parseInt(time[7..9].paddingRight('000'), 10)
    else
      hours = '0'
      minutes = '0'
      seconds = '0'
      milliseconds = '000'
      if op.warnIfMissing
        @pushWarnings('parsing', ["Missing time part for `#{tag}`"])
    new Date(Date.UTC(year, month, day, hours, minutes, seconds, milliseconds))

  @parse: (file) ->
    image = new ImageUploader.Models.Image
    image.parse(file)

  imagingDateTime: ->
    if @get('seriesDateTime')?
      @get('seriesDateTime')
    else if not @get('contentDateTime')?
      @get('acquisitionDateTime')
    else if not @get('acquisitionDateTime')?
      @get('contentDateTime')
    else if @get('contentDateTime') < @get('acquisitionDateTime')
      @get('acquisitionDateTime')
    else
      @get('contentDateTime')

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
        @clearWarnings('upload')
      error: (response) =>
        @set state: 'upload failed'
        @pushWarnings('upload', response.responseJSON?.errors)
      cache: false
      processData: false
      contentType: false

  hasWarnings: (action) ->
    if action?
      not _.isEmpty(@warnings[action])
    else
      not _.isEmpty(@warnings)

  hasErrors: () ->
    isSevere = (key, errors) -> key != 'parsing' and _.isEmpty(errors)
    _.some(@warnings, isSevere)

  formatWarnings: ->
    _.chain(@warnings)
      .map (warnings, action) ->
        return [] unless warnings?
        _(warnings).map (warning) -> "#{action.capitalize()}: #{warning}"
      .flatten()
      .value()

  pushWarnings: (action, warnings) ->
    warnings = Array.ensureArray(warnings)
    @warnings[action] ||= []
    for warning in warnings when warning not in @warnings[action]
      @warnings[action].push(warning)
      console.log warning
    @trigger('warnings')

  clearWarnings: (action) ->
    delete @warnings[action]
    @trigger('warnings')
