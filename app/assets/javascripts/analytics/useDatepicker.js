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
      $('input.dummy').hide();
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
        $('input.dummy').show();

        // ホーム画面の判別
        if ($('title').text().indexOf('ホーム') == 0) {

          // ページ遷移直後は全体ページ、
          // バブル描画後は描画されたページの項目を格納
          var wd = $('div#narrow div').text() === 'undefined' ? '全体' : $('div#narrow div').text();

          // ajaxリクエストを実行
          callExecuter(wd);
        } else {

          // ホーム画面でないときは非ajaxリクエストを実行
          $('a#set').trigger('click');
        }
      },
      "キャンセル": function(){
        $(this).dialog('close');

        // datepickerを自動表示させない
        $('#dummy').show();
      }
    }
  });

  // ログイン直後ダイアログの設定ボタンをクリックした後の確認ダイアログ

// ↓エラー発生
// TypeError: $(...).data(...) is null
// .data( widgetFullName )._focusTabbable();

  $('#onlogin-dialog-confirm').dialog({
    closeOnEscape: false,
    autoOpen: false,
    draggable: false,
    dialogClass: 'jquery-ui-dialog-onlogin-confirm',
    open:function(event, ui){

      // 期間メッセージを表示
      var f = $("#from").val();
      var t = $("#to").val();
      var msg = f + "～" + t + "　の期間で分析をします。"
      $("#onlogin-dialog-confirm p#confirm-msg").text(msg);

      // タイトルバーを非表示
      $("div.ui-dialog-titlebar").hide();

      // ダイアログの角を丸くしない
      $(".ui-corner-all").css({
        "border-top-right-radius": "0px",
        "border-top-left-radius": "0px",
        "border-bottom-right-radius": "0px",
        "border-bottom-left-radius": "0px"
      });

      // ダイアログのサイズを変更
      $(".jquery-ui-dialog-onlogin-confirm").css({
        "font-family": "inherit",
        "font-size": "25px",
        "text-align": "center",
      });

      // 設定ボタンのサイズを変更
      $("#onlogin-dialog-confirm a").css({
        "margin": "0 0 0 40px",
        "text-decoration": "none",
        "padding": "5px 30px 0px 30px",
        "color": "#ffffff",
        "background-color": "#808080",
      });

      // 設定ボタンのサイズを変更
      $('#onlogin-dialog-confirm a').hover(
        function(){
            $(this).css("background-color","#C0C0C0");
        },function(){
            $(this).css("background-color","#808080");
        }
      );

      // 分析開始ボタンの動作
      $( "a#go" ).click(function() {
        $("#onlogin-dialog-confirm").dialog('close');
        // $('#onlogin-dialog-confirm').dialog('open');
      });

      // 期間修正ボタンの動作
      $( "a#cancel" ).click(function() {
        $('#onlogin-dialog').dialog('open');
        $("#onlogin-dialog-confirm").dialog('close');
      });
    },
    width: 1000,
    height: 300,
    modal: true,
  });

  // ログイン直後に表示する期間設定ダイアログ
  $('#onlogin-dialog').dialog({
    closeOnEscape: false,
    autoOpen: false,
    draggable: false,
    dialogClass: 'jquery-ui-dialog-onlogin',
    open:function(event, ui){

      // タイトルバーを非表示
      $("div.ui-dialog-titlebar").hide();

      // ダイアログの角を丸くしない
      $(".ui-corner-all").css({
        "border-top-right-radius": "0px",
        "border-top-left-radius": "0px",
        "border-bottom-right-radius": "0px",
        "border-bottom-left-radius": "0px"
      });

      // datepickerを自動表示させない
      $('input.dummy').hide();

      // ダイアログのサイズを変更
      $(".jquery-ui-dialog-onlogin").css({
        "font-family": "inherit",
        "font-size": "25px",
        "text-align": "center",
      });

      // 日付入力ボックスのサイズを変更
      $("input.hasDatepicker").css({
        "width": "200px",
        "height": "42px",
        "text-align": "center",
      })

      // 設定ボタンのサイズを変更
      $("a#start").css({
        "margin": "0 0 0 40px",
        "text-decoration": "none",
        "padding": "5px 30px 0px 30px",
        "color": "#ffffff",
        "background-color": "#808080",
      });

      // 設定ボタンのサイズを変更
      $('a#start').hover(
        function(){
            $(this).css("background-color","#C0C0C0");
        },function(){
            $(this).css("background-color","#808080");
        }
      );

      // 確認ダイアログを表示
      $( "a#start" ).click(function() {
        $('#onlogin-dialog-confirm').dialog('open');
        $('#onlogin-dialog').dialog('close');
      });
    },
    width: 1000,
    height: 300,
    modal: true,
  });

  // 日付のリンクをクリックしたら、現在の期間設定をダイアログへ
  // 反映させる
  $( "a#jrange" )
    .click( function() {
      var v = $(this).text(), d, f, t;

      d = v.split('-');

       f = '20' + d[0];
       t = '20' + d[1];

      $('input.fromd').datepicker('setDate', f);
      $('input.tod').datepicker('setDate', t);

      $( "#dialog-form" ).dialog('open');
  });

  // ダイアログ内のdatepicker
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
          maxDate: opt
        }
      );
      // console.log( "to val change, " + $("input.tod").val() );
      // $("#to").val( $("input.tod").val() );
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
          minDate: opt,
          maxDate: selectedDate
        }
      );
      // console.log( "fromd val change, " + $("input.fromd").val() );
      // $("#from").val( $("input.fromd").val() );
    }
  });

});
