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
  var from = $('#from').val().substr(2);
  var to = $('#to').val().substr(2);
  var range = from + '-' + to;
  var txt = $('a#jrange').html().split(">");
  txt2 = txt[0] + '>' + range;
  $('a#jrange').html(txt2);
}

// ホーム画面の絞り込み箇所のオーバーレイcssを再設定するコード
function handler(event) {
  $('div.plainoverlay').css(
    {
      height: '42px',
      cursor: 'auto',
      top: '-14px',
      'min-width': '1200px',
      'background-color': 'white',
      width: '100%',
    }
  );
}

// ブラウザのウインドウがリサイズされた場合、ホーム画面のオーバーレイcssを更新するイベント
var timer = false;
$(window).resize(function() {
    if (timer !== false) {
        clearTimeout(timer);
    }
    timer = setTimeout(function() {
        // オーバーレイcssの再設定
        handler();
    }, 200);
});

$(document).ready(function() {

  // ホーム画面の時のみ、絞り込み機能を日付以外オーバレイする
  if ($('title').text().indexOf('ホーム') == 0) {
    $('span#poverlay').plainOverlay('show',
      {
        progress: false,
        show: handler
      }
    );
  }

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

  // 訪問者、デバイス毎にチェックボックスの複数選択を抑止
  $('form [name=device]').click(function() {
    likeRadio($(this));
  });
  $('form [name=visitor]').click(function() {
    likeRadio($(this));
  });

  // ajax中に別ページへの通常リクエストが発生したらajax消去
  $("body").bind("ajaxSend", function(c, xhr) {
      $( window ).bind( 'beforeunload', function() {
          xhr.abort();
      })
  });

  // 絞り込みボタンを押したとき、プログレススピナーを起動する
  $('a#set').click(function(){

    // スピナーの実装
    if ( $('#entrance.spinner').length <= 0) {
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
  // $('td.gap').each(function() {
  //   var str = $(this).text();
  //   if( str.substr(0,1) == "-" ) {
  //     $(this).css("color", "red");
  //   // } else {
  //   //   $(this).css("color", "black");
  //   }
  // });

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

    // ホーム画面に戻るときはプロット処理を実行させない
    if ($(this).text() == 'ホーム') {
      $('input[name="shori"]').val('0');
    }
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

  // ホーム画面で指定した項目を赤で強調表示する
  // 目標値のある項目は目標の数値。それ以外は数値を強調表示する
  if (gon.red_item) {
    var i = gon.red_item;
    switch (String(i)) {
      case 'PV数':
        // 数値
        $('#kitchen table tr:nth-child(2) td:first').css("color", "red");
        break;
      case '平均PV数':
        // 目標値
        $('#kitchen table tr td.markpv').css("color", "red");
        break;
      case '訪問回数':
        // 数値
        $('#kitchen table tr:nth-child(2) td:nth-child(2)').css("color", "red");
        break;
      case '直帰率':
        // 数値
        $('#knife table tr td:nth-child(2)').css("color", "red");
        break;
      case '新規訪問率':
        // 目標値
        $('#kitchen table tr td.marknew').css("color", "red");
        break;
      case '平均滞在時間':
        // 目標値
        $('#kitchen table tr td.marktime').css("color", "red");
        break;
      case '再訪問率':
        // 目標値
        $('#kitchen table tr td.markrpt').css("color", "red");
        break;
      case '人気ページ':
        // 目標値
        var w = $('#narrow_select').val();
        var kwd = w.substr(0, w.length - 1);
        $('#bedroom table tbody tr:contains(' + kwd + ') td:first').css("color", "red");
        break;
      }
  }

  // グラフ表示項目の選択値を保持
  var grh_fmt = gon.graphic_item
  $('select[name="graphicselect"]').val(grh_fmt);
  $('input[name="graphic_item"]').val(grh_fmt);

  // CV種類の選択値を保持
  var cv = gon.cv_num
  $('select[name="cvselect"]').val(cv);
  $('input[name="cv_num"]').val(cv);

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
