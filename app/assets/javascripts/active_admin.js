//= require active_admin/base

// Stub batch actions initializer so that the scopes buttons are not
// automatically restyled to fit the original ActiveAdmin layout.
// Everything is happening in the CSS.

//= require jquery.sortable
//= require reorder_case_list
//= require reorder_visits

//= require select2-full
//= require vendor/jsoneditor
//= require vendor/jsoneditor.erica-theme
//= require cases_advanced_filters
//= require aa_advanced_filters
//= require tree.jquery
//= require aa_erica_keywords
//= require vendor/underscore
//= require extensions
//= require vendor/polyfill_setAsap
//= require vendor/polyfill_promise
//= require vendor/polyfill_srcdoc.min
//= require vendor/naturalSort
//= require vendor/Chart.bundle
//= require vendor/Chart.even-tick-distribution
//= require shared/promise_queue
//= require shared/user
//= require select2-initializers
//= require bootstrap-sprockets
//= require bootstrap/scrollspy
//= require bootstrap/modal
//= require bootbox
//= require erica_menu
//= require_self
//= require cable

bootbox.setDefaults({ size: "small" });
$.fn.select2.defaults.set("theme", "bootstrap");

var rails = $.rails;
$.rails.handleMethod = function (link) {
  var overridePromptParam = link.data("override-prompt-param"),
    overridePromptText = link.data("override-prompt-text");

  var href;
  if (overridePromptParam) {
    var promptValue = prompt(overridePromptText);
    if (promptValue === null) return;

    var url = new URL(rails.href(link));
    var params = url.searchParams;
    params.set(overridePromptParam, promptValue);
    url.search = params.toString();
    href = url.toString();
  } else {
    href = rails.href(link);
  }

  var method = link.data("method"),
    target = link.attr("target"),
    csrfToken = rails.csrfToken(),
    csrfParam = rails.csrfParam(),
    form = $('<form method="post" action="' + href + '"></form>'),
    metadataInput =
      '<input name="_method" value="' + method + '" type="hidden" />';

  if (
    csrfParam !== undefined &&
    csrfToken !== undefined &&
    !rails.isCrossDomain(href)
  ) {
    metadataInput +=
      '<input name="' +
      csrfParam +
      '" value="' +
      csrfToken +
      '" type="hidden" />';
  }

  if (target) {
    form.attr("target", target);
  }

  form.hide().append(metadataInput).appendTo("body");
  form.submit();
};
