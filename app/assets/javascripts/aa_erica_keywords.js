$(document).ready(function () {
  //
  //
  $(".tagfilter").each(function () {
    $(this).select2();
  });
  $(".tagselect").each(function () {
    var $el = $(this);
    var placeholder = $el.data("placeholder");
    var url = $el.data("url");
    var saved = $el.data("saved");
    var allow_new = $el.data("allownew");

    $(this).select2({
      multiple: true,
      tags: allow_new, //
      placeholder: placeholder,
      minimumInputLength: 1,
      ajax: {
        url: url,
        dataType: "json",
        data: function (params) {
          return { q: params.term };
        },
        processResults: function (data) {
          return {
            results: data.map(function (tag) {
              return {
                id: tag,
                text: tag,
              };
            }),
          };
        },
      },
      createSearchChoice: function (term, data) {
        if (!allow_new) {
          return;
        }
        if (
          $(data).filter(function () {
            return this.text.localeCompare(term) === 0;
          }).length === 0
        ) {
          return { id: term, text: term };
        }
      },
    });
  });
});
