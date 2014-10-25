// バブルチャート取得用のオプション配列
var opts = [];

// バブルチャート取得用のオプション
var dev, usr, kwd;

// オプション配列用のカウンタ
var opts_cntr = 0;

// 絞り込み用キーワード
var kwd_opts = [];

// バブルチャート描画用のデータオブジェクト
var r_obj = {};

// バブルチャート表示リクエストの処理開始、完了フラグ
// 0: 未処理 1: 処理中 2: 処理終了
var bbl_shori_flg = 0;

// ajaxリクエスト格納
var request;

// ajaxリクエスト格納(並列用)
// var requests = [];

// ユーザが所有しているgaアカウントの配列
// var gaccounts = [];

// ajax並列リクエスト用の遅延時間配列
// var gadelays = [0.4, 0.8, 0.6];
// var gadelays = [0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8, 2, 2.2];
// var gadelays = [0.4, 0.6, 0.8, 1, 1.2, 1.4, 1.6, 1.8];
// var gadelays = [0.4, 0.6, 0.8, 1, 1.2];

// バブルチャート用データのリクエスト（非同期）
function callExecuter(elem) {

  // ajax二重リクエストの防止
  if (request) {
    $("span#errormsg").html('只今処理の実行中です。');
    return;
  }

  // elem引数から、表示するページ項目を取り出す
  if ($.type(elem) === 'object') {
    elm_txt = elem.text();
  } else {
    elm_txt = String(elem);
  }

  // ページ遷移先の設定
  var userpath = gon.narrow_action;

  // 最初のリクエスト時のみ実行
  if (bbl_shori_flg == 0) {

    // 表示項目のリセット
    $('#gp').replaceWith('<div id="gp" style="z-index: 1;"></div>');
    $('#legend1b').empty();
    $('#errormsg').empty();

    // 進捗画面の生成
    var shaft = {
      lines: 13, // The number of lines to draw
      length: 15, // The length of each line
      width: 9, // The line thickness
      radius: 18, // The radius of the inner circle
      corners: 1, // Corner roundness (0..1)
      rotate: 0, // The rotation offset
      direction: 1, // 1: clockwise, -1: counterclockwise
      color: '#000', // #rgb or #rrggbb or array of colors
      speed: 1, // Rounds per second
      trail: 60, // Afterglow percentage
      shadow: false, // Whether to render a shadow
      hwaccel: false, // Whether to use hardware acceleration
      className: 'spinner', // The CSS class to assign to the spinner
      zIndex: 2e9, // The z-index (defaults to 2000000000)
      top: '50%', // Top position relative to parent
      left: '50%' // Left position relative to parent
    };
    var spinner = new Spinner(shaft).spin();

    // ローディング画面の表示とバブルチャートのオーバーレイ
    $('#gp').plainOverlay(
      'show',
      {
        opacity: 0.2,
        progress: function() {

          // ローディング中のメッセージを生成
          var target = $('<div id="guardian"></div><table id="daemon"><tr><td>分析中 ...</td></tr><tr><td>　</td></tr><tr><td></td></tr></table>');

          return target;
        }
    });
    $('#guardian').append(spinner.el);

    // 項目一覧のオーバレイ
    $('div#info').plainOverlay('show', {opacity: 0.2, progress: false});

    // ページ項目に合わせた絞り込みキーワードを取得する
    // この時点では絞り込みオプションを指定しない
    console.log( '絞り込み用キーワード取得対象 : ' + String(elm_txt));
    console.log( '絞り込み用キーワード取得処理の開始');

    $.ajax({
      url: userpath,
      async: false,
      dataType: 'json',
      data: {
        from : $('#from').val(),
        to : $('#to').val(),
        cv_num : $('input[name="cv_num"]').val(),
        shori : $('input[name="shori"]').val(),
        act : elm_txt, // 取得するページ項目
      }
    })
    .done(function(data, textStatus, jqXHR) {
      var d = JSON.parse(data.homearr);
      console.log( '絞り込み用キーワード取得完了');
      console.log(d);
      $.extend(true, kwd_opts, d);
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      $('span#errormsg').html('絞り込み用キーワード取得エラーが発生しました： ' + String(errorThrown));
    })
    .always(function() {
      console.log('絞り込み用キーワード取得処理の終了');

      var dev_opts = [ // デバイス
        'pc',
        'sphone',
        'mobile',
      ];
      var usr_opts = [ // 訪問者
        'new',
        'repeat'
      ];

      // パラメータの全ての組み合わせを網羅した配列を作る
      for (var i = 0; i <= dev_opts.length; i++) {
        for (var j = 0; j <= usr_opts.length; j++) {
          for (var k = 0; k <= kwd_opts.length; k++) {
            opts.push( {dev: dev_opts[i], usr: usr_opts[j], kwd: kwd_opts[k] });
          }
        }
      }

      console.log('全パラメータ組み合わせ数 : ' + String(opts.length));

      // 初期リクエスト用のパラメータを設定
      dev = String(opts[opts_cntr].dev); // undefined の場合はサーバ側でall を指定する
      usr = String(opts[opts_cntr].usr); // undefined の場合はサーバ側でall を指定する
      kwd = String(opts[opts_cntr].kwd) === "undefined"? 'nokwd' : String(opts[opts_cntr].kwd);
    });

    // // ユーザ所有のgaアカウントを取得
    // $.ajax({
    //   url: userpath,
    //   async: false,
    //   dataType: 'json',
    //   data: {
    //     shori : $('input[name="shori"]').val(),
    //     gaccnt : 'true', // GAアカウントを取得するか？
    //     kwd : 'nokwd'
    //   }
    // })
    // .done(function(data, textStatus, jqXHR) {
    //   var d = JSON.parse(data.homearr);
    //   console.log( '所有GAアカウント情報取得完了');
    //   console.log(d);
    //   $.extend(true, gaccounts, d);
    // })
    // .fail(function(jqXHR, textStatus, errorThrown) {
    //   $('span#errormsg').html('所有GAアカウント取得エラーが発生しました： ' + String(errorThrown));
    // })
    // .always(function() {
    //   console.log('所有GAアカウント取得処理の終了');
    // });

  // ajax処理中
  bbl_shori_flg = 1;

  }

  // ディレイ時間の分、ajaxリクエストを作成
  // for (var i = 0; i < gadelays.length; i++) {

    // リクエスト用のパラメータを設定
    // dev = String(opts[opts_cntr].dev); // undefined の場合はサーバ側でall を指定する
    // usr = String(opts[opts_cntr].usr); // undefined の場合はサーバ側でall を指定する
    // kwd = String(opts[opts_cntr].kwd) === "undefined"? 'nokwd' : String(opts[opts_cntr].kwd);

    // 遅延時間を取得
    // var gadelay = gadelays[i];

  // ajaxリクエストの生成
  request = $.Deferred(function(deferred) {
    $.ajax({
      url: userpath,
      type:'GET',
      dataType: "json",
      tryCount: 0,
      // timeout: 2000, // 単位はミリ秒
      retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
      beforeSend: function(XMLHttpRequest) {

        // 最初のリクエスト時のみ実行
        if (bbl_shori_flg == 0) {

          console.log( 'ajax通信開始!');

        }
      },
      // バブルチャート用データ取得用のパラメータ
      data: {
        from : $('#from').val(),
        to : $('#to').val(),
        cv_num : $('input[name="cv_num"]').val(),
        shori : $('input[name="shori"]').val(),
        act : elm_txt,             // 取得するページ項目
        dev : dev,                 // デバイス
        usr : usr,                   // 訪問者
        kwd : kwd,                 // キーワード
        // gadelay : gadelay      // リクエスト遅延時間
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

    // リクエストを配列へ格納
    // requests.push(request);
    // console.log('requests contains below');
    // console.log(requests);

    // パラメータ配列のカウンタを進める
    // opts_cntr++;

    // パラメータ配列が無くなったらajax生成のforループを抜ける
    // if (opts_cntr <= opts.length - 1) {

    //   // リクエストを処理中
    //   bbl_shori_flg = 1;
    // } else {

    //   // リクエストを処理終了
    //   bbl_shori_flg = 2;
    //   break;
    // }

  // }

  // 並列リクエストだとアナリティクスAPIの割り当て制限エラーに引っ掛かるので逐次リクエストへ変更。
  // ⇒ 2014/10/19 GAアカウントの所有数だけ並列でリクエストを実施することで、API制限を回避。
  // ⇒ 2014/10/25 API制限回避できず。直列方式へ再度変更
  request.done(function(data, textStatus, jqXHR) {
  // $.when.apply($, requests).done(function(data, textStatus, jqXHR) {

    console.log( 'ajax通信成功!');

    // 結果は仮引数に可変長で入る **順番は保証されている**
    // 取り出すには arguments から取り出す
    // さらにそれぞれには [data, textStatus, jqXHR] の配列になっている
    // for (i=0; i < arguments.length; i++) {
    //   var result = arguments[i];
    //   var r_obj_tmp = JSON.parse(result[0].homearr);
    //   $.extend(true, r_obj, r_obj_tmp);
    // }

    // グラフ描画用のデータをマージ
    var r_obj_tmp = JSON.parse(data.homearr);
    $.extend(true, r_obj, r_obj_tmp);

    // 項目名、フィルタ名の取得
    var page_fltr_wd = data.page_fltr_wd;
    var page_fltr_dev = data.page_fltr_dev;
    var page_fltr_usr = data.page_fltr_usr;
    var page_fltr_kwd = data.page_fltr_kwd;
    // var page_fltr_wd = result[0].page_fltr_wd;
    // var page_fltr_dev = result[0].page_fltr_dev;
    // var page_fltr_usr = result[0].page_fltr_usr;
    // var page_fltr_kwd = result[0].page_fltr_kwd;

    // カウンタを進める
    opts_cntr++;

    // フィルタリングオプションの配列が無くなるまでajaxを実行
    if (opts_cntr <= opts.length - 1) {

    // if (bbl_shori_flg == 1) {

      // リクエストを処理中
      // bbl_shori_flg = 1;
      callManager(bbl_shori_flg); // システム動作継続のため、リクエスト変数をリセット

      console.log('ajax通信に成功しました。');
      console.log('デバイス : ' + page_fltr_dev + ' 訪問者 : ' + page_fltr_usr + ' キーワード : ' + page_fltr_kwd );
      console.log('ajax処理を継続します');

      // リクエスト用のパラメータを設定し、ajaxを再実行
      dev = String(opts[opts_cntr].dev); // undefined の場合はサーバ側でall を指定する
      usr = String(opts[opts_cntr].usr); // undefined の場合はサーバ側でall を指定する
      kwd = String(opts[opts_cntr].kwd) === "undefined"? 'nokwd' : String(opts[opts_cntr].kwd);

      // ローディング画面に進捗を表示
      var prcnt = parseInt( (opts_cntr / opts.length) * 100 );
      $('#daemon tr:nth-child(3) td').text(String(prcnt) + '%');

      // ajax処理を再実行
      callExecuter(page_fltr_wd);
    } else {
    // else if (bbl_shori_flg = 2) {

      // リクエストを処理終了
      bbl_shori_flg = 2;
      callManager(bbl_shori_flg);

      console.log('ページ絞り込み名 :' + page_fltr_wd);

      // ローディング完了テキストを表示
      $('#daemon tr:nth-child(3) td').text('complete!');

      // バブルチャートを描画
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
    }

    // リクエスト実行時のエラーメッセージ表示をリセット
    $('#errormsg').empty();
  })

  // ajax失敗時の処理
  .fail(function(jqXHR, textStatus, errorThrown) {
    console.log( 'ajax通信失敗!通信を中断します');
    console.log(errorThrown);

    if (errorThrown == 'timeout') {
      $("span#errormsg").html('リクエストがタイムアウトしました。時間を置いて再度実行してください。<br>改善されない場合は担当者までお問い合わせください。<p/>');
    } else {
      $("span#errormsg").html('エラーが発生しました。 下記のエラーコードをお控えのうえ、担当者までお問い合わせください。<br>エラーコード : '+ String(errorThrown) );
    }

    // 失敗したら処理終了
    bbl_shori_flg = 2;
    callManager(bbl_shori_flg);
  })

  // ajax通信終了時に常に呼び出される処理
  .always(function() {

    // リクエスト処理が終了した場合に実行される
    if (bbl_shori_flg == 2) {

      console.log( 'ajax通信終了!');

      // ローディングアニメーションのリセット
      $('#gp').plainOverlay('hide');
      $('div#info').plainOverlay('hide');

      // リクエストを未処理状態へ
      bbl_shori_flg = 0;

      // カウンタをリセット
      opts_cntr = 0;

      // パラメータ配列をリセット
      opts = [];

      // バブルチャート描画用のデータオブジェクトをリセット
      r_obj = {};

      // 絞り込み用キーワードのリセット
      kwd_opts = [];

      // ユーザが所有しているgaアカウントの配列をリセット
      // gaccounts = [];

    }
  });
}

// 二重送信防止のため、リクエストが未処理以外のときは送信リクエスト変数をリセットする
function callManager(flg) {

  if (flg != 0) {
    request = '';
    requests = [];
  }
}
