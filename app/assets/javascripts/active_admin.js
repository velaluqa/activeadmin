//= require active_admin/base

// Stub batch actions initializer so that the scopes buttons are not
// automatically restyled to fit the original ActiveAdmin layout.
// Everything is happening in the CSS.
//= stub active_admin/initializers/batch_actions

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

bootbox.setDefaults({ size: 'small' });
$.fn.select2.defaults.set( "theme", "bootstrap" );
