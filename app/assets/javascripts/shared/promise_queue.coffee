class @PromiseQueue
  constructor: (size) ->
    throw new Error('Missing queue size') unless size?
    @size = size
    @tasks = []
    @active = []
    @guid = 0
    @autostart = false

  next: ->
    return if @active.length >= @size
    if @tasks.length is 0
      @allPromise?.resolve() if @active.length is 0
      return
    task = @tasks.shift()
    id = @guid++
    resolve = (r) =>
      @active.splice(@active.indexOf(id), 1)
      task.resolve(r)
      @next()
    reject = (r) =>
      @active.splice(@active.indexOf(id), 1)
      task.reject(r)
      @next()
    task.handler().then(resolve, reject)
    @active.push(id)

  push: (handler) ->
    return new Promise (resolve, reject) =>
      @tasks.push
        handler: handler
        resolve: resolve
        reject: reject

  start: ->
    @next() for i in [0..@size]
    new Promise (resolve, reject) =>
      @allPromise = {
        resolve: resolve
        reject: reject
      }
