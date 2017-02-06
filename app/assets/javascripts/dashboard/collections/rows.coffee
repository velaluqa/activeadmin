@Dashboard ?= {}
@Dashboard.Collections ?= {}
class Dashboard.Collections.Rows extends Backbone.Collection
  model: Dashboard.Models.Row
