@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Main extends Backbone.Model
  initialize: (options = {}) ->
    @rows = new Dashboard.Collections.Rows(options.config.rows)
