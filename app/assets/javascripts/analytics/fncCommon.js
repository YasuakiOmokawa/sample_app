function likeRadio(obj) {
  var n = obj.attr("name");
  var m = '#hallway input[name=' + n + ']';
  var objs = $(m);
  var f = objs, cnt = 0;
  for(var i=0;i<f.length;i++ ){
    if ( f[i].checked === true ) {
      cnt = cnt + 1;
    }
  }
  if (cnt >= 2) {
    f.prop("checked", false); // 属性値の状態を取得するならpropのほうが良いってさ。。
    obj.prop("checked", true);
    console.log("hello like Radio!");
  }
}

// 指定した要素をフォーム送信ボタンをクリックしたときと同じ動作にする
var evtset = function (at) {
  $('#hallway > form').attr("action", at.attr("name"));
  console.log(at);
}
var evtsend = function (at) {
  $('#hallway > form').attr("action", at.attr("name"));
  $('a#set').trigger('click');
}

// 期間設定ボックスの初期値を設定
var setRange = function setRange() {
  var range = $('#from').val() + ' ~ ' + $('#to').val();
  $('#jrange input').val(range);
}

// バブルチャートのリクエストを実施したときのイベント（非同期）
function callExecuter() {
  var userpath = gon.narrow_action;
  var xhr;
  xhr = $.ajax({
    type:'GET',
    dataType: "json",
    url: userpath,
    data: {
      from : $('#from').val(),
      to : $('#to').val(),
      cv_num : $('input[name="cv_num"]').val(),
      shori : $('input[name="shori"]').val()
    }
  });
  return xhr.done(function(result) {
    console.log( '通信成功！');

    // ホーム画面のグラフと項目一覧の描画
    var r_obj = JSON.parse(result.homearr);
    plotGraphHome(r_obj);

  }).fail(function(result) {
    console.log( '通信失敗！');
  });
}

// Ajaxの通信中は、ローディング画像を表示
$(document).ajaxSend(function() {

  // 描画用htmlの整理
  $('#gp').empty();
  $('#legend1b').empty();

  $(".loading").show();
  $("#cboxOverlay").css("opacity", "0.3").show();
});

// Ajax通信が完了したら、ローディング画像の削除
$(document).ajaxComplete(function() {
  $("#cboxOverlay").fadeOut(1000);
  $(".loading").fadeOut(1000);
});


$(document).ready(function() {

  // CVの選択のセレクトボックスを選択したときのイベント
  $('select#cvselect').change(function() {
      $('input[name="cv_num"]').val($(this).val());
  });

  // グラフに表示する項目のセレクトボックスを選択したときのイベント
  $('select#graphicselect').change(function() {
    $('input[name="graphic_item"]').val($(this).val());
    $('a#set').trigger('click');
  });

  // タイトルがカスタマイズの時の独自処理を追加
  if ( $(this).attr("title").indexOf('カスタマイズ') != -1 ) {
    $('div#hallway').hide();
    $('div#footer').attr("id", 'footer_custom');
  }

  // チェックボックスの複数選択を抑止
  $('form [name=device]').click(function() {
    likeRadio($(this));
  });
  $('form [name=visitor]').click(function() {
    likeRadio($(this));
  });

  // 絞り込みボタンを押したとき、プログレススピナーを起動する
  $('a#set').click(function(){

    // ホーム画面の絞り込みボタンだった場合、スピナーを起動させない
    // $('a#set').attr("class")

      // スピナーの実装
      if ( $('.spinner').length <= 0) {
        var opts = {
          lines: 13, // The number of lines to draw
          length: 4, // The length of each line
          width: 2, // The line thickness
          radius: 3, // The radius of the inner circle
          corners: 1, // Corner roundness (0..1)
          rotate: 0, // The rotation offset
          direction: 1, // 1: clockwise, -1: counterclockwise
          color: 'white', // #rgb or #rrggbb or array of colors
          speed: 1, // Rounds per second
          trail: 60, // Afterglow percentage
          shadow: false, // Whether to render a shadow
          hwaccel: false, // Whether to use hardware acceleration
          className: 'spinner', // The CSS class to assign to the spinner
          zIndex: 2e9, // The z-index (defaults to 2000000000)
        };
        var target = $('#entrance');
        var spinner = new Spinner(opts).spin();
        target.append(spinner.el);
        $('.spinner').css('margin-top', 2);
      }

  });

  // escボタンを押したとき、プログレススピナーをキャンセルする
  $(window).keydown(function(e){
    if( e.keyCode == 27 ) {
      $('.spinner').remove();
    }
  });

  // GAP値がマイナスなら赤色にする
  $('td.gap').each(function() {
    var str = $(this).text();
    if( str.substr(0,1) == "-" ) {
      $(this).css("color", "red");
    // } else {
    //   $(this).css("color", "black");
    }
  });

  // 曜日ごとに背景色を変更
  // 土。。薄い青　日、祝。。　薄い赤
  $('td[data-day]').each(function() {

    var dtype = $(this).attr("data-day");

    if ( (dtype == 'day_sun') || (dtype == 'day_hol') )  {
      $(this).css("background-color", "#FFEEFF");
    } else if (dtype == 'day_sat') {
      $(this).css("background-color", "#EEFFFF");
    }
  });

  // 選択したページタブのタグをdiv へ変える
  var tab = gon.div_page_tab;
  var tag = 'li#' + tab + ' a';
  var id = '<div>';
  if ( $(tag).html().match(/<br>/) ) {
    id = '<div id="db">';
  }
  $(tag).replaceWith(id + $(tag).html() + '</div>');

  // 各ページのタブへリンク付与
  $("li.tab a").click(function(){
    evtsend($(this));
  });

  // ラジオボタンの選択値を保持
  var rdo_dev = gon.radio_device
  var rdo_vst = gon.radio_visitor
  $('input[name="device"]').val([rdo_dev]);
  $('input[name="visitor"]').val([rdo_vst]);

  // セレクトボックスの選択値を保持
  var nrw_wd = gon.narrow_word
  $('select[name="narrow_select"]').val(nrw_wd);

  // グラフ表示項目の選択値を保持
  var grh_fmt = gon.graphic_item
  $('select[name="graphicselect"]').val(grh_fmt);
  $('input[name="graphic_item"]').val(grh_fmt);

  // CV種類の選択値を保持
  var cv = gon.cv_num
  $('select[name="cvselect"]').val(cv);
  $('input[name="cv_num"]').val(cv);

  // ページ読み込み時の期間設定ボックス設定
  setRange();

  // セレクトボックスの色を変更
  var dColor = '#999999';
  var fColor = '#000000';
  if ( $('#narrow_select').val() == "" ){
    $('#narrow_select').css('color', dColor);
  } else {
    $('#narrow_select').css('color', fColor);
  }
  $('#narrow_select')
    .focus(function() {
      $('#narrow_select').css('color', fColor);
    })
    .blur(function() {
      if ( $('#narrow_select').val() == "" ){
        $('#narrow_select').css('color', dColor);
      } else {
        $('#narrow_select').css('color', fColor);
      }
  });
});
