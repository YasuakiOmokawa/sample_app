function initDatepicker() {
  var to = new Date();
  var from = new Date(to.getTime() - 1000 * 60 * 60 * 24 * 14);
  var init_text = fmt(from)+' - '+fmt(to);

  // Datepicker は複数設定させないようにする
  if ( $('#datepicker-calendar').children().length == 0 ) {
    $('#datepicker-calendar').DatePicker({
      inline: true,
      date: [from, to],
      calendars: 3,
      mode: 'range',
      current: new Date(to.getFullYear(), to.getMonth() - 1, 1),
      onChange: function(dates, el) {
        // from と to が選択されてから処理を実行する
        if ( fmt(dates[0]) != fmt(dates[1]) ) {
          var text = fmt(dates[0])+' - '+fmt(dates[1]);
          $('#date-range-field span').text(text); // update the range display
          $("input[name='content[date]']")
            .val(text)
            .change(); // update the form date
        }
      }
    });
  }

  // initialize the special date dropdown field
  $('#date-range-field span').text("選択してください");
  // $("input[name='content[date]']").val(init_text);
}

function bindDatepickerOperation() {

  // initialize the special date dropdown field
  // $('#date-range-field span').text("選択してください");

  // bind a click handler to the date display field, which when clicked
  // toggles the date picker calendar, flips the up/down indicator arrow,
  // and keeps the borders looking pretty
  // $('#date-range-field').click(function(){
  //   // $('#datepicker-calendar').toggle();
  //   if($('#date-range-field a').text().charCodeAt(0) == 9660) {
  //     // switch to up-arrow
  //     $('#date-range-field a').html('&#9650;');
  //     $('#date-range-field').css({borderBottomLeftRadius:0, borderBottomRightRadius:0});
  //     $('#date-range-field a').css({borderBottomRightRadius:0});
  //   } else {
  //     // switch to down-arrow
  //     $('#date-range-field a').html('&#9660;');
  //     $('#date-range-field').css({borderBottomLeftRadius:5, borderBottomRightRadius:5});
  //     $('#date-range-field a').css({borderBottomRightRadius:5});
  //   }
  //   return false;
  // });

  // global click handler to hide the widget calendar when it's open, and
  // some other part of the document is clicked.  Note that this works best
  // defined out here rather than built in to the datepicker core because this
  // particular example is actually an 'inline' datepicker which is displayed
  // by an external event, unlike a non-inline datepicker which is automatically
  // displayed/hidden by clicks within/without the datepicker element and datepicker respectively
  // $('html').click(function() {
  //   if($('#datepicker-calendar').is(":visible")) {
  //     // $('#datepicker-calendar').hide();
  //     $('#date-range-field a').html('&#9660;');
  //     $('#date-range-field').css({borderBottomLeftRadius:5, borderBottomRightRadius:5});
  //     $('#date-range-field a').css({borderBottomRightRadius:5});
  //   }
  // });

  // stop the click propagation when clicking on the calendar element
  // so that we don't close it
  // $('#date-range-hidden').click(function(event){
  $('#date-range').click(function(event){
    event.stopPropagation();
  });

}

// function isLocationHash() {
//   if (location.hash) {
//     return location.hash;
//   } else {
//     return "#all";
//   }
// }

// 日付計算
var calc = function(datestr, p, day) {
  var dt = new Date(datestr);
  switch(p) {
    case '+' :
    dt.setDate(dt.getDate() + day);
    break;
    case '-' :
    dt.setDate(dt.getDate() - day);
    break;
  }
  return dt;
}

// 日付フォーマット
var fmt = function(dt) {
  var year = dt.getFullYear();
  var month = dt.getMonth() + 1;
  var day = dt.getDate();

  if ( month < 10 ) {
  　　month = '0' + month;
  }
  if ( day < 10 ) {
  　　day = '0' + day;
  }
  var str = year + '/' + month + '/' + day;
  return str;
}

// カレンダーの位置を調整
var chgPos = function(input, inst, elm) {
  var cal = inst.dpDiv;
  var top  = elm.offset().top + elm.outerHeight();
  var left = elm.offset().left;
  setTimeout(function() {
    cal.css({
      'top' : top,
      'left': left
    });
   }, 10);
}

// 日付リンクの期間設定を入力ダイアログへ反映させる
function addRangeToDatePicker() {
    var v = $("a#jrange").text(), d, f, t;

    d = v.split('-');

     f = '20' + d[0];
     t = '20' + d[1];

    $('input.fromd').datepicker('setDate', f);
    $('input.tod').datepicker('setDate', t);
}

// // ダイアログ内のdatepicker
// function addDatepicker() {
//   $("input.fromd").datepicker({
//     changeMonth: true,
//     changeYear: true,
//     numberOfMonths: 2,
//     dateFormat:"yy/mm/dd",
//     beforeShow: function(input, inst) {
//       chgPos(input, inst, $(this));
//     },
//     onSelect: function( selectedDate ) {
//       var dte = calc(selectedDate, '+', 31);
//       var opt = fmt(dte);
//       $( "#from" ).val(selectedDate);
//       $( "input.tod" ).datepicker( "option",
//         {
//           minDate: selectedDate,
//           // maxDate: opt
//         }
//       );
//     }
//   });

//   $("input.tod").datepicker({
//     changeMonth: true,
//     changeYear: true,
//     numberOfMonths: 2,
//     dateFormat:"yy/mm/dd",
//     beforeShow: function(input, inst) {
//       chgPos(input, inst, $(this));
//     },
//     onSelect: function( selectedDate ) {
//       var dte = calc(selectedDate, '-', 31);
//       var opt = fmt(dte);
//       $( "#to" ).val(selectedDate);
//       $( "input.fromd" ).datepicker( "option",
//         {
//           // minDate: opt,
//           maxDate: selectedDate
//         }
//       );
//     }
//   });
// }

// $(function() {

//   // 期間設定ダイアログ
//   $('#dialog-form').dialog({
//     autoOpen: false,
//     draggable: false,
//     dialogClass: 'jquery-ui-dialog-form',
//     open:function(event, ui){

//       // datepickerを設定
//       addDatepicker();

//       // 日付リンクから、期間設定をダイアログの入力ボックスへ転記
//       addRangeToDatePicker();

//       // datepicker を表示させるため、初期focus を行う。
//       $("div.jquery-ui-dialog-form").focus();

//     },
//     width: 400,
//     height: 200,
//     title: '期間設定',
//     modal: true,
//     position: {
//       my: "left top",
//       at: "left top",
//       of: 'a#jrange'
//     },
//     buttons: {
//         "設定": function(){

//           // 入力ボックスの値を#from, #to へ格納
//           $("#from").val( $("input.fromd").val() );
//           $("#to").val( $("input.tod").val() );

//           $(this).dialog('close');

//           // 入力値を期間設定のhidden inputへ設定
//           setRange();

//           // datepicker の削除
//           $("input.fromd").datepicker("destroy");
//           $("input.tod").datepicker("destroy");

//           if (isTitleHome()) {
//             changeLocationHash(getLocationHashPage());
//           } else {
//             $('a#set').trigger('click');
//           }
//       },
//       "キャンセル": function(){
//         $(this).dialog('close');

//         // datepickerを削除
//         $("input.fromd").datepicker("destroy");
//         $("input.tod").datepicker("destroy");
//       }
//     }
//   });
// });


