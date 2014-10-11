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

// バブルチャート用データのリクエスト（非同期）
function callExecuter(elem) {

  // ページ遷移先(同一ページ内)
  var userpath = gon.narrow_action;

  // 取得ページ項目の絞り込みオプション
  var opts = [
    'all',
    'pc',
    'sphone',
    'mobile',
    'new',
    'repeat'
  ];

  var requests = [];
  var datas = {};
  datas[elem.text()] = {};


  for (var i=0; i < opts.length; i++) {

    // 絞り込みオプションを文字列へ変換
    var opt_txt = String(opts[i]);

    // ajaxリクエストの生成
    var request = $.Deferred(function(deferred) {
      $.ajax({
        url: userpath,
        type:'GET',
        dataType: "json",
        tryCount: 0,
        // timeout: 2000, // 単位はミリ秒
        retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
        beforeSend: function(XMLHttpRequest) {

          console.log( 'ajax通信開始!');
          console.log( opts[i]);

          // 表示項目のリセット
          $('#gp').replaceWith('<div id="gp" style="z-index: 1;"></div>');
          $('#legend1b').empty();
          $('#errormsg').empty();

          // ローディング画面の表示
          $('#gp').plainOverlay('show', {opacity: 0.2});
          $('div#info').plainOverlay('show', {opacity: 0.2, progress: false});
        },
        data: {
          from : $('#from').val(),
          to : $('#to').val(),
          cv_num : $('input[name="cv_num"]').val(),
          shori : $('input[name="shori"]').val(),
          act : elem.text(), // 取得するページ項目
          fltr : opt_txt // 取得するページのフィルタリング項目
        },
        error: function(xhr, ajaxOptions, thrownError) {

          // 内部エラーが発生したら表示
          if (xhr.status == 500) {
            $("span#errormsg").html('status 500 : サーバー応答エラーです。時間を置いて再度実行してください。<br>改善されない場合は担当者へお問い合わせ下さい。<p/>');
            return;
          }

          this.tryCount++;

          if (this.tryCount < this.retryLimit) {

            console.log('ajax通信失敗。再試行します : ' + String(this.tryCount) + '回目');

            $.ajax(this).done(function(data, textStatus, jqXHR) {
              deferred.resolveWith(this, [data, textStatus, jqXHR]);
            }).fail(function(jqXHR, textStatus, errorThrown) {
              if (this.tryCount >= this.retryLimit) {

                console.log('再試行の上限に達しました。エラー処理を実行します。');

                deferred.rejectWith(this, [jqXHR, textStatus, errorThrown]);
              }
            });
          }
        }
      }).done(function(data, textStatus, jqXHR) {
        deferred.resolveWith(this, [data, textStatus, jqXHR]);
      });
    }).promise();

    // ajaxリクエストを後でまとめて実行するため、配列へ格納
    requests.push(request);

  }

  // request.done(function(data, textStatus, jqXHR) {
  // ajaxリクエストを並列で実行。
  // $.whenは可変長引数を取るので、applyメソッドを利用して配列で渡せるようにする
  // $.whenのコンテキスト(applyの第一引数)はjQueryである必要があるので $ を渡す
  $.when.apply($, requests)

  // 成功時の処理
    .done(function() {
      console.log( 'ajax通信成功!');

      // グラフ描画用のデータ
      var r_obj = {};

      // 結果は仮引数に可変長で入る **順番は保証されている**
      // 取り出すには arguments から取り出す
      // さらにそれぞれには [data, textStatus, jqXHR] の配列になっている
      for (i=0; i < arguments.length; i++) {

        var result = arguments[i];
        var r_obj_tmp = JSON.parse(result[0].homearr);

        // データをマージ
        $.extend(true, r_obj, r_obj_tmp);

      }

      // 項目名、フィルタ名の取得
      var page_fltr_wd = result[0].page_fltr_wd;
      // var page_fltr_opt = result[0].page_fltr_opt;

      console.log('ページ絞り込み名 :' + page_fltr_wd);
      plotGraphHome(r_obj, page_fltr_wd);

      // ホームグラフのページ項目タグがdivになっていればリセットする
      var h, y;
      h = $('div#narrow div');
      if (h.html() != 'キャンペーン' ) {
        y = '<a href="javascript:void(0)" onclick="callExecuter($(this));" >';
      } else {
        y = '<a id="ed" href="javascript:void(0)" onclick="callExecuter($(this));" >';
      }
      $(h).replaceWith(y + $(h).html() + '</a>');

      // 選択したホームグラフのページ項目タグをdivへ変更
      if (page_fltr_wd == '直接入力ブックマーク') {
        page_fltr_wd = '直接入力/ブックマーク'
      }
      var tag = 'div#narrow a:contains(' + page_fltr_wd + ')';
      var id = '<div>';
      var r_tag = $(tag).replaceWith(id + $(tag).html() + '</div>');
      if (page_fltr_wd == 'キャンペーン') {
        $('div#narrow div').attr('id', 'ed');
      }
    })

    // ajax失敗時の処理
    .fail(function(jqXHR, textStatus, errorThrown) {
    // request.fail(function(jqXHR, textStatus, errorThrown) {
      console.log( 'ajax通信失敗!');
      console.log(errorThrown);

      if (errorThrown == 'timeout') {
        $("span#errormsg").html('リクエストがタイムアウトしました。時間を置いて再度実行してください。<br>改善されない場合は担当者までお問い合わせください。<p/>');
      } else {
        $("span#errormsg").html('エラーが発生しました。 下記のエラーコードをお控えのうえ、担当者までお問い合わせください。<br>エラーコード : '+ String(errorThrown) );
      }

      // 失敗したら処理を抜ける
      return false;

    })

    // ajax通信終了時に常に呼び出される処理
    // request.always(function() {
    .always(function() {
      $('#gp').plainOverlay('hide');
      $('div#info').plainOverlay('hide');
      console.log( 'ajax通信終了!');
    });

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

// ウインドウがリサイズされた場合、ホーム画面のオーバーレイcssを更新するイベント
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

  // ログイン直後、もしくは他のページタブからホーム画面に遷移した場合、
  // ajaxイベントを実施する
  if (gon.div_page_tab || gon.div_page_tab != "first") {
    var wd = '全体';
    var txt = 'div#narrow a:contains(' + wd + ')';
    $(txt).trigger('click');
  }

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

  // チェックボックスの複数選択を抑止
  $('form [name=device]').click(function() {
    likeRadio($(this));
  });
  $('form [name=visitor]').click(function() {
    likeRadio($(this));
  });

  // ajax中にイベント発生したらイベント消去
  $("body").bind("ajaxSend", function(c, xhr) {
      $( window ).bind( 'beforeunload', function() {
          xhr.abort();
      })
  });

  // 絞り込みボタンを押したとき、プログレススピナーを起動する
  $('a#set').click(function(){

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
