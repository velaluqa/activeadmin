@Dashboard ?= {}
@Dashboard.Collections ?= {}
class Dashboard.Collections.Widgets extends Backbone.Collection
  model: Dashboard.Models.Widget
