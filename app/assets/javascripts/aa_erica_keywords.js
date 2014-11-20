$(document).ready(function() {
    $('.tagselect').each(function() {
        var placeholder = $(this).data('placeholder');
        var url = $(this).data('url');
        var saved = $(this).data('saved');
	var allow_new = $(this).data('allownew');
        $(this).select2({
	    multiple: true,
	    tags: allow_new,
            placeholder: placeholder,
            minimumInputLength: 1,
            initSelection : function(element, callback){
                saved && callback(saved);
            },
            ajax: {
                url: url,
                dataType: 'json',
                data:    function(term) { return { q: term }; },
                results: function(data) { return { results: data }; }
            },
            createSearchChoice: function(term, data) {
		if(!allow_new) { return; }

                if ($(data).filter(function() {
                    return this.name.localeCompare(term)===0;
                }).length===0) {
                    return { id: term, name: term };
                }
            },
            formatResult:    function(item, page){ console.log(item); return item.name; },
            formatSelection: function(item, page){ console.log(item); return item.name; }
        });
    });
});
