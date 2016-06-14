@ILR ?= {}
class ILR.User
  permissionsMatrix: {}

  constructor: (permissionsMatrix = {}) ->
    @permissionsMatrix = permissionsMatrix

  can: (activities, subject) ->
    activities = Array.ensureArray(activities)
    subjectActivities = Array.ensureArray(@permissionsMatrix[subject])
    return true if 'manage' in subjectActivities

    activityGranted = (activity in subjectActivities for activity in activities)
    _.some(activityGranted)
