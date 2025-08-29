// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery.remotipart
//= require datatables
//= require popper
//= require moment
//= require fullcalendar
//= require bootstrap
//= require cocoon
//= require chosen-jquery
//= require jquery.multi-select
//= require bootstrap-multiselect
//= require datetimepicker
//= require chartkick
//= require clipboard
//= require Chart.bundle
//= require plyr
//= require pusher
//= require toastr
//= require adminlte.min
//= require_tree .

$(document).ready(function() {
  handleAdvanceSearch();
  handleSubscription();
  handlePusherSubscription();
  bulkSelectOperations();
  singleSelectOperations();
  toggleShowMoreLess();
  togglePassword();
  initiateCalender();
  initiateLeadCalender();
  $(".dataTables").dataTable({
    "iDisplayLength": 50,
    responsive: true,
    bPaginate: false,
    bFilter: false
  });
  $('.multi-select-list').multiselect({
    numberDisplayed: 1,
    enableFiltering: true,
    enableCaseInsensitiveFiltering: true,
    nonSelectedText: 'Please Select',
    includeSelectAllOption: true,
    buttonWidth: '100%',
    maxHeight: 350,
  });

  // clipboard js

  $('.clipboard-btn').tooltip({
    trigger: 'click',
    placement: 'top'
  });

  $('.chosen-select').chosen({
    allow_single_deselect: true,
    no_results_text: 'No results matched',
    width: '350px'
  });

  function setTooltip(btn, message) {
    $(btn).tooltip('show')
      .attr('data-original-title', message)
      .tooltip('show');
  }

  function hideTooltip(btn) {
    setTimeout(function() {
      $(btn).tooltip('hide');
    }, 1000);
  }

  var clipboard = new Clipboard('.clipboard-btn');
  clipboard.on('success', function(e) {
    setTooltip(e.trigger, 'Copied!');
    hideTooltip(e.trigger);
  });

  clipboard.on('error', function(e) {
    setTooltip(e.trigger, 'Failed!');
    hideTooltip(e.trigger);
  });

  // clipboard js ends
  var date = new Date();
  var today = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  $('.datetimepicker').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss"});
  $('.datetimepickerncd').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss", minDate: today});
  $('.datetimepickerleaseexpired').datetimepicker({timepicker: false,format:'d/m/Y', maxDate: today});
  // For Modal
  $(document).on('show.bs.modal', '#modal-window', function() {
    $('.datetimepicker').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss"});
    $('.datetimepickerncd_modal').datetimepicker({dateFormat: "yy-mm-dd HH:ii:ss", minDate: today});
    $('.dateFormat').datetimepicker({
      timepicker: false,
      format:'d/m/Y'
    });
  })
  $('.dateFormat').datetimepicker({
    timepicker: false,
    format:'d/m/Y'
  });


});
function handleAdvanceSearch() {
  $('#adv-search').click(function() {
    $('#adv-searchbox').toggle(300);
    icon = $('#adv-search').children('i');
    if (icon.hasClass('fa-angle-down')) {
      icon.removeClass('fa-angle-down').addClass('fa-angle-up')
    } else {
      icon.removeClass('fa-angle-up').addClass('fa-angle-down')
    }
  });
}


function bulkSelectOperations() {
  $('.select-all').on('change', function() {
    if(this.checked) {
      $('.bulk-select').each(function() {
        this.checked = true;
      });
      $('div.bulk-process').show();
    } else {
      $('.bulk-select').each(function() {
        this.checked = false;
      });
      $('div.bulk-process').hide();
    }
  });
}

function singleSelectOperations() {
  $('input.bulk-select').on('change', function() {
    if($('input.bulk-select:checked').length) {
      $('div.bulk-process').show();
    } else {
      $('div.bulk-process').hide();
    }
  });
}

function toggleShowMoreLess(){
  var moretext = "Show more >";
  var lesstext = "Show less <";
  $('.showmore').each(function() {
    var ellipsestext = "...";
    showChar = 50
    var content = $(this).html();
    if(content.length > showChar) {
      var c = content.substr(0, showChar);
      var h = content.substr(showChar, content.length - showChar);
      var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="javascript:void(0)" class="morelink">' + moretext + '</a></span>';
      $(this).html(html);
    }
  });
  $(".morelink").click(function(){
    if($(this).hasClass("less")) {
      $(this).removeClass("less");
      $(this).html(moretext);
    } else {
      $(this).addClass("less");
      $(this).html(lesstext);
    }
    $(this).parent().prev().toggle();
    $(this).prev().toggle();
    return false;
  });
}
var a = ['','one ','two ','three ','four ', 'five ','six ','seven ','eight ','nine ','ten ','eleven ','twelve ','thirteen ','fourteen ','fifteen ','sixteen ','seventeen ','eighteen ','nineteen '];
var b = ['', '', 'twenty','thirty','forty','fifty', 'sixty','seventy','eighty','ninety'];
function inWords (num) {
    if ((num = num.toString()).length > 9) return 'overflow';
    n = ('000000000' + num).substr(-9).match(/^(\d{2})(\d{2})(\d{2})(\d{1})(\d{2})$/);
    if (!n) return; var str = '';
    str += (n[1] != 0) ? (a[Number(n[1])] || b[n[1][0]] + ' ' + a[n[1][1]]) + 'crore ' : '';
    str += (n[2] != 0) ? (a[Number(n[2])] || b[n[2][0]] + ' ' + a[n[2][1]]) + 'lakh ' : '';
    str += (n[3] != 0) ? (a[Number(n[3])] || b[n[3][0]] + ' ' + a[n[3][1]]) + 'thousand ' : '';
    str += (n[4] != 0) ? (a[Number(n[4])] || b[n[4][0]] + ' ' + a[n[4][1]]) + 'hundred ' : '';
    str += (n[5] != 0) ? ((str != '') ? 'and ' : '') + (a[Number(n[5])] || b[n[5][0]] + ' ' + a[n[5][1]]) + '' : '';
    return str;
  }

function togglePassword(){
  $("#show_hide_password a").on('click', function(event) {
    event.preventDefault();
    if($('#show_hide_password input').attr('type') == 'text'){
      $('#show_hide_password input').attr('type', 'password');
      $('#show_hide_password i').addClass( "fa-eye-slash" );
      $('#show_hide_password i').removeClass( "fa-eye" );
      } else if($('#show_hide_password input').attr('type') == 'password') {
      $('#show_hide_password input').attr('type', 'text');
      $('#show_hide_password i').removeClass( "fa-eye-slash" );
      $('#show_hide_password i').addClass( "fa-eye" );
    }
  });
}


function handleSubscription(){
  if (gon.can_subscribe){
    (function(p,u,s,h,x){p.pushpad=p.pushpad||function(){(p.pushpad.q=p.pushpad.q||[]).push(arguments)};h=u.getElementsByTagName('head')[0];x=u.createElement('script');x.async=1;x.src=s;h.appendChild(x);})(window,document,'https://pushpad.xyz/pushpad.js');
    pushpad('init', gon.project_id, {serviceWorkerPath: '/service-worker.js'});
    if (window.sessionStorage.getItem('notification-status') != 'subscribed'){
      pushpad('subscribe', function () {
        window.sessionStorage.setItem('notification-status', 'subscribed');
      });
    }
    pushpad('tags', ['web_app']);
    pushpad('uid', gon.user_uuid, gon.hmac_signature);
  }
}

function initiateCalender(){
  $('#calendar').fullCalendar({
    header: {
      left: 'prev,next today',
      center: 'title',
      today:    'hoy',
      month:    'month',
      week:     'week',
      day:      'day',
      right: 'month,agendaWeek,agendaDay'
    },
    events: '/reports/scheduled_site_visits.json',
    eventClick: function(event, element) {
      var event_id = event.id
      var url = '/reports/'+event_id+'/scheduled_site_visits_detail/'
      if ($(element.target).attr('value') == "Edit"){
        url = '/leads/'+event_id+'/edit/'
      }
      $.ajax({
        type: 'GET',
        url: url,
        dataType: 'script'
      });
    },
    eventRender: function(eventObj, element){
      element.find('.fc-content').append("<span class='fc-edit pull-right'><i class='fa fa-pencil' value='Edit'></i></span>");
    }
  });
}

function initiateLeadCalender(){
  $('#lead-calendar').fullCalendar({
    themeSystem: 'bootstrap',
    header: {
      left: 'prev,next today',
      center: 'title',
      today:    'hoy',
      month:    'month',
      week:     'week',
      day:      'day',
      right: 'month,agendaWeek,agendaDay'
    },
    events: 'calender_view.json',
    eventClick: function(event, element) {
      var event_id = event.id
      var url = '/reports/'+event_id+'/scheduled_site_visits_detail/'
      if ($(element.target).attr('value') == "Edit"){
        url = '/leads/'+event_id+'/edit/'
      }
      $.ajax({
        type: 'GET',
        url: url,
        dataType: 'script'
      });
    },
    eventRender: function(eventObj, element){
      element.find('.fc-content').append("<span class='fc-edit pull-right'><i class='fa fa-pencil' value='Edit'></i></span>");
    }
  });
}

