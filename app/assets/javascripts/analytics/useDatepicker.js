function isLocationHash() {
  if (location.hash) {
    return location.hash;
  } else {
    return "#all";
  }
}

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

// ダイアログ内のdatepicker
function addDatepicker() {
  $("input.fromd").datepicker({
    changeMonth: true,
    changeYear: true,
    numberOfMonths: 2,
    dateFormat:"yy/mm/dd",
    beforeShow: function(input, inst) {
      chgPos(input, inst, $(this));
    },
    onSelect: function( selectedDate ) {
      var dte = calc(selectedDate, '+', 31);
      var opt = fmt(dte);
      $( "#from" ).val(selectedDate);
      $( "input.tod" ).datepicker( "option",
        {
          minDate: selectedDate,
          // maxDate: opt
        }
      );
    }
  });

  $("input.tod").datepicker({
    changeMonth: true,
    changeYear: true,
    numberOfMonths: 2,
    dateFormat:"yy/mm/dd",
    beforeShow: function(input, inst) {
      chgPos(input, inst, $(this));
    },
    onSelect: function( selectedDate ) {
      var dte = calc(selectedDate, '-', 31);
      var opt = fmt(dte);
      $( "#to" ).val(selectedDate);
      $( "input.fromd" ).datepicker( "option",
        {
          // minDate: opt,
          maxDate: selectedDate
        }
      );
    }
  });
}

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


