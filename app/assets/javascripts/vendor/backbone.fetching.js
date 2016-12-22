Backbone.Model.extend({
    initialize: function() {
        this.isFetched = false;
        this.bind("reset", this.onReset, this);
    },
    oldFetch: Backbone.Model.prototype.fetch,
    fetch: function(options) {
	this.trigger("fetching");
	this.isFetching = true;
	oldFetch(options);
    },
    onReset: function() {
        this.isFetching = false;
    }
});
