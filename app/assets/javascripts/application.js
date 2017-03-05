// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery-ui
//= require jquery-ui/widgets/autocomplete
//= require jquery_ujs
//= require_tree .
//= require bootstrap-sprockets

$(document).ready(function() {
  $('#navbar-search').autocomplete({
    source: '/account/search',
    minLength: 3,
    select: function(event, ui) {
      window.location.href = '/account/' + ui.item.value;
    }
  }).focus();
});