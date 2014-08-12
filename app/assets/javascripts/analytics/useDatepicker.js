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


$(function() {

  // 期間設定ダイアログ
  $('#dialog-form').dialog({
    closeOnEscape: false,
    autoOpen: false,
    draggable: false,
    open:function(event, ui){
      $(".ui-dialog-titlebar-close").hide();
      // datepickerを自動表示させない
      $('#dummy').hide();
    },
    width: 400,
    height: 200,
    title: '期間設定',
    modal: true,
    position: {
      my: "left top",
      at: "left top",
      of: 'a#jrange'
    },
    buttons: {
      "設定": function(){
        $(this).dialog('close');
        // 入力値を期間設定ボックスへ設定
        setRange();
      // datepickerを自動表示させない
      $('#dummy').show();
      // ページ遷移を行う
      $('a#set').trigger('click');
      },
      "キャンセル": function(){
        $(this).dialog('close');
        // datepickerを自動表示させない
        $('#dummy').show();
      }
      // "クリア": function(){
      //   $.datepicker._clearDate( '#fromd' );
      //   $.datepicker._clearDate( '#tod' );
      //   ['#tod', '#fromd'].forEach(function(i) {
      //     $( i ).datepicker( "option", {
      //       minDate: null,
      //       maxDate: null } );
      //   });
    }
  });

  // 日付のリンクをクリックしたら、現在の期間設定をダイアログへ
  // 反映させる
  $( "a#jrange" )
    .click( function() {
      var v = $(this).text(), d, f, t;

      d = v.split('-');

       f = '20' + d[0];
       t = '20' + d[1];

      $('#fromd').datepicker('setDate', f);
      $('#tod').datepicker('setDate', t);

      $( "#dialog-form" ).dialog('open');
  });

  // ダイアログ内のdatepicker
  $("#fromd").datepicker({
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
      $( "#tod" ).datepicker( "option",
        {
          minDate: selectedDate,
          maxDate: opt
        }
      );
      console.log( "to val change, " + $("#tod").val() );
      $("#to").val( $("#tod").val() );
    }
  });
  $("#tod").datepicker({
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
      $( "#fromd" ).datepicker( "option",
        {
          minDate: opt,
          maxDate: selectedDate
        }
      );
      console.log( "fromd val change, " + $("#fromd").val() );
      $("#from").val( $("#fromd").val() );
    }
  });

});
