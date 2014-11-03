// ajaxリクエスト格納
var request;

// バブルチャート表示リクエストの処理開始、完了フラグ
// 0: 未処理 1: 処理中 2: 処理終了
var bbl_shori_flg = 0;

// ページ全体ローディング中のカウンタ
var prcnt_all_cntr = 0;

// バブルチャート取得関数
function callOwner(elem, robj) {

  console.log( 'ajax通信開始!');

  // ページ遷移先の設定
  var userpath = gon.narrow_action;

  // バブルチャート取得用のオプション配列
  var opts = [];

  // バブルチャート取得用のオプション
  var dev, usr, kwd;

  // オプション配列用のカウンタ
  var opts_cntr = 0;

  // 表示項目のリセット
  resetHome();

  // ページ個別のローディングであればローディングモーションを表示
  if (! $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").isVisible()) {
    setLoadingMortion();
  }

  // オプションキーワードを生成
  var kwd_opts = setKwds(elem, userpath);

  // オプション配列を生成
  setOpts(opts, kwd_opts);

  // キャッシュ用ユニーク文字数を格納
  var kwd_strgs = createCacheKeyNum(kwd_opts);

  // キャッシュ済データを取得
  var data;
  var c_obj = cacheResult(data, false, 'GET', 'kobetsu', kwd_strgs, elem);

  // キャッシュ済データがあるか？
  if (c_obj) {

    // データマージ
    $.extend(true, robj, c_obj);
  } else {

    // ajax処理中
    bbl_shori_flg = 1;

    var tmp_obj = {};

    // データリクエストを実行
    callExecuter(elem, opts, userpath, opts_cntr, robj, tmp_obj, kwd_strgs);
  }
}

// バブルチャートをオーバーレイ
function addOverlay() {

  $('#gp').plainOverlay(
    'show',
    {
      opacity: 0.2,
      progress: function() {
        var target = $('<div id="guardian"></div><table id="daemon"><tr><td>分析中 ...</td></tr><tr><td>　</td></tr><tr><td></td></tr></table>');
        return target;
      }
  });
}

// プログレススピナーを生成
function createSpinner() {

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

  return spinner;
}

// 表示項目のリセット
function resetHome() {

  $('#gp').replaceWith('<div id="gp" style="z-index: 1;"></div>');
  $('#legend1b').empty();
  $('#errormsg').empty();
}

// ページ項目に合わせた絞り込みキーワードを取得する
function setKwds(elem, userpath) {

  // 返り値
  var dt = [];

  // ページ項目に合わせた絞り込みキーワードを取得する
  // この時点では絞り込みオプションを指定しない
  console.log( '絞り込み用キーワード取得対象 : ' + String(elem));
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
      act : elem, // 取得するページ項目
    }
  })

  .done(function(data, textStatus, jqXHR) {
    var d = JSON.parse(data.homearr);
    console.log( '絞り込み用キーワード取得完了');
    console.log(d);
    $.extend(true, dt, d);
  })

  .fail(function(jqXHR, textStatus, errorThrown) {
    $('span#errormsg').html('絞り込み用キーワード取得エラーが発生しました： ' + String(errorThrown));
  })

  .always(function() {
    console.log('絞り込み用キーワード取得処理の終了');
  });

  return dt;
}

// パラメータの全ての組み合わせを網羅した配列を作る
function setOpts(opts, kwd_opts) {

  var dev_opts = [ // デバイス
    // 'pc',
    // 'sphone',
    // 'mobile',
  ];

  var usr_opts = [ // 訪問者
    // 'new',
    // 'repeat'
  ];

  for (var i = 0; i <= dev_opts.length; i++) {
    for (var j = 0; j <= usr_opts.length; j++) {
      for (var k = 0; k <= kwd_opts.length; k++) {
        opts.push( {dev: dev_opts[i], usr: usr_opts[j], kwd: kwd_opts[k] });
      }
    }
  }
  console.log('全パラメータ組み合わせ数 : ' + String(opts.length));
}

// キャッシュ用キー文字数を生成
function createCacheKeyNum(kwd_opts) {

  // 返り値
  var kwd_strgs = 0;

  // キーワードの総文字数を格納
  if (kwd_opts.length >= 1) {
    for (var k = 0; k < kwd_opts.length; k++) {
      var x = kwd_opts[k];
      kwd_strgs = kwd_strgs + parseInt(x.length);
    }
  }

  return kwd_strgs;
}

// elem引数から、表示するページ項目を取り出す
function parseElem(elem) {

  var elm_txt;

  if ($.type(elem) === 'object') {
    elm_txt = elem.text();
  } else {
    elm_txt = String(elem);
  }
  return elm_txt;
}

// バブルチャート用データのリクエスト（非同期）
function callExecuter(elm_txt, opts, userpath, opts_cntr, robj, tmp_obj, kwd_strgs) {

  if (elm_txt == '直接入力/ブックマーク') {
    elm_txt = '直接入力ブックマーク';
  }

  // ajaxリクエストの生成
  if (bbl_shori_flg == 1) {

    // ajaxリクエスト用のパラメータを設定
    var dev = String(opts[opts_cntr].dev); // undefined の場合はサーバ側でall を指定する
    var usr = String(opts[opts_cntr].usr); // undefined の場合はサーバ側でall を指定する
    var kwd = String(opts[opts_cntr].kwd) === "undefined"? 'nokwd' : String(opts[opts_cntr].kwd);

    request = $.Deferred(function(deferred) {
      $.ajax({
        url: userpath,
        type:'GET',
        dataType: "json",
        tryCount: 0,
        // timeout: 2000, // 単位はミリ秒
        retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
        beforeSend: function(XMLHttpRequest) {
          // なんかあったら追加
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
  }

  // 並列リクエストだとアナリティクスAPIの割り当て制限エラーに引っ掛かるので逐次リクエストへ変更。
  // ⇒ 2014/10/19 GAアカウントの所有数だけ並列でリクエストを実施することで、API制限を回避。
  // ⇒ 2014/10/25 API制限回避できず。直列方式へ再度変更

  if (request) {

    request.done(function(data, textStatus, jqXHR) {

      console.log( 'ajax通信成功!');

      // グラフ描画用のデータをマージ
      var r_obj_tmp = JSON.parse(data.homearr);
      $.extend(true, tmp_obj, r_obj_tmp);

      // 項目名、フィルタ名の取得
      var page_fltr_wd = data.page_fltr_wd;
      var page_fltr_dev = data.page_fltr_dev;
      var page_fltr_usr = data.page_fltr_usr;
      var page_fltr_kwd = data.page_fltr_kwd;

      // オプションの配列のカウンタを進める
      opts_cntr++;

      // フィルタリングオプションの配列が無くなるまでajaxを実行
      if (opts_cntr <= opts.length - 1) {

        callManager(bbl_shori_flg); // システム動作継続のため、リクエスト変数をリセット

        console.log('ajax通信に成功しました。');
        console.log('デバイス : ' + page_fltr_dev + ' 訪問者 : ' + page_fltr_usr + ' キーワード : ' + page_fltr_kwd );
        console.log('ajax処理を継続します');

        // 進捗を表示
        if ($(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").isVisible()) {

          // ページ全体の進捗カウンタを進める
          prcnt_all_cntr++;

          // 進捗を算出
          var prcnt_all = calcProgress(prcnt_all_cntr, 380);

          // ダイアログに進捗を表示
          displayProgress('.jquery-ui-dialog-onlogin div#onlogin-dialog-confirm div#monsterball', prcnt_all);
        } else {

          // ページ個別の進捗を算出
          var prcnt = calcProgress(opts_cntr, opts.length);

          // 画面に進捗を表示
          displayProgress('#daemon tr:nth-child(3) td', prcnt);
        }

        // ajax処理を再実行
        callExecuter(page_fltr_wd, opts, userpath, opts_cntr, robj, tmp_obj, kwd_strgs)
      } else {

        // リクエストを処理終了
        bbl_shori_flg = 2;
        callManager(bbl_shori_flg);

        console.log('ページ絞り込み名 :' + page_fltr_wd);

        // ローディング完了テキストを表示
        $('#daemon tr:nth-child(3) td').text('complete!');

      // グラフ描画用のデータを最終マージ
      $.extend(true, robj, tmp_obj);

    // ページ全体ロードの時はデータをキャッシュさせない
    if (! $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").isVisible()) {
      cacheResult(robj, true, 'POST', 'kobetsu', kwd_strgs, elm_txt);
    }

      }
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

      }
    });
  }

}

// 二重送信防止のため、リクエストが未処理以外のときは送信リクエスト変数をリセットする
function callManager(flg) {

  if (flg != 0) {
    request = '';
  }
}

// 処理完了時のリセット処理
function afterCall() {
  // ローディングアニメーションのリセット
  $('#gp').plainOverlay('hide');
  $('div#info').plainOverlay('hide');

  // リクエスト実行時のエラーメッセージ表示をリセット
  $('#errormsg').empty();

  // ajaxリクエストをリセット
  request = '';

  // バブルチャート処理フラグをリセット
  bbl_shori_flg = 0;

}

// ホームグラフのページ項目タグがdivになっていればリセットする
function markPageBtn(page) {
  var h, y;
  h = $('div#narrow div');
  if (h.html() != 'キャンペーン' ) {
    y = '<a href="javascript:void(0)" onclick="bubbleCreateAtTabLink($(this));" >';
  } else {
    y = '<a id="ed" href="javascript:void(0)" onclick="bubbleCreateAtTabLink($(this));" >';
  }
  $(h).replaceWith(y + $(h).html() + '</a>');

  // 選択したホームグラフのページ項目タグをdivへ変更
  if (page == '直接入力ブックマーク') {
    page = '直接入力/ブックマーク'
  }
  var tag = 'div#narrow a:contains(' + page + ')';
  var id = '<div>';
  var r_tag = $(tag).replaceWith(id + $(tag).html() + '</div>');
  if (page == 'キャンペーン') {
    $('div#narrow div').attr('id', 'ed');
  }
}

// バブル作成用にページ下部のタブリンクに埋め込む関数
function bubbleCreateAtTabLink(wd) {

  // ajax二重リクエストの防止
  if (request) {
    $("span#errormsg").html('只今処理の実行中です。');
    return;
  }

  // 返り値データ
  var idxarr = [], arr = [];

  // wd引数から、表示するページ項目を取り出す
  var elm_txt = parseElem(wd);

  createBubbleWithParts(idxarr);

  createBubbleParts(elm_txt, idxarr);

}

// バブル作成用のパーツを生成する関数
function createBubbleParts(wd, idxarr) {

  // オブジェクト
  var robj = {};

  // ajaxリクエストを実行
  callOwner(wd, robj);

  // 返り値データをポーリング
  var timerID = setInterval( function(){
   if(Object.keys(robj).length != 0){

      // wd が直接入力ブックマーク の場合、スラッシュを削除
      if (wd == '直接入力/ブックマーク') {
        wd = wd.replace(/\//g, '');
      }

      // データ項目一覧セット
      setDataidx(robj, wd, idxarr);

      // ページ名のdivタグをグレーアウト
      markPageBtn(wd);

     clearInterval(timerID);
     timerID = null;
    }
  },100);
}

// 全ページ種類のグラフを生成する関数
function createBubbleAll(idxarr, idxarr_all, page_fltr_wds, pcntr, origin_content) {

  // バブル用のパーツ作成
  createBubbleParts(page_fltr_wds[pcntr], idxarr);

  // 返り値データをポーリング
  var timerID = setInterval( function(){
   if(Object.keys(idxarr).length != 0){

      // データマージ
      Array.prototype.push.apply(idxarr_all, idxarr);

      // データリセット
      idxarr = [];

      // increment counter
      pcntr++;

      // 全部のページ種類の分析が終わった？
      if (pcntr >= 6) {

        // バブルチャートを作成
        createBubbleWithParts(idxarr_all);

        setTimeout(function() {

          afterCallWithPlotAll(origin_content);

          var shaped_idxarr = [];

          // 優先順位の降順、
          // 　ページ名と項目名の昇順でソート
          // > がマイナスリターン。。降順、< がプラスリターンで昇順
          shaped_idxarr = sortIdxarr(idxarr_all);

          // 項目を指定数分取り出す
          shaped_idxarr = headIdxarr(idxarr_all, 30);

          // 作成済みデータをキャッシュ
          cacheResult(shaped_idxarr, true, 'POST', 'zentai');
        }, 1000);

      } else {

        createBubbleAll(idxarr, idxarr_all, page_fltr_wds, pcntr, origin_content);
      }

     clearInterval(timerID);
     timerID = null;
    }
  },100);
}

// 生成されたパーツを使ってバブルチャートを作成
function createBubbleWithParts(idxarr) {

  // 返り値データをポーリング
  var timerID = setInterval( function(){
   if(Object.keys(idxarr).length != 0){

      var shaped_idxarr = [];

      // 優先順位の降順、
      // 　ページ名と項目名の昇順でソート
      // > がマイナスリターン。。降順、< がプラスリターンで昇順
      shaped_idxarr = sortIdxarr(idxarr);

      // 項目を指定数分取り出す
      shaped_idxarr = headIdxarr(idxarr, 30);

      // プロットデータの作成
      var arr = [];
      createPlotArr(shaped_idxarr, arr);

      // バブルチャートを描画
      plotGraphHome(arr, shaped_idxarr);

      // 事後処理
      afterCall();

      clearInterval(timerID);
      timerID = null;

    }
  },100);
}

// ローディング進捗の計算
function calcProgress(opts_cntr, length) {
  var prcnt = parseInt( (opts_cntr / length) * 100 );
  return prcnt;
}

// 指定要素へ進捗率を表示
function displayProgress(prgtarget, prcnt) {

  var trgt = String(prgtarget);

  $(trgt).text(String(prcnt) + '%');
}

// ページ個別のモーションを設定
function setLoadingMortion() {

  // プログレススピナーを生成
  var spinner = createSpinner();

  // バブルチャートをオーバーレイ
  addOverlay();

  // プログレススピナーを表示
  $('#guardian').append(spinner.el);

  // 項目一覧のオーバレイ
  $('div#info').plainOverlay('show', {opacity: 0.2, progress: false});
}

// ダイアログへ全体進捗を表示
function addLoadingMortion() {

  // 元のコンテンツを保存
  var origin_content = $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").html();

  // プログレススピナーを生成
  var spinner = createSpinner();

  // ボタンを消去
  $(".jquery-ui-dialog-onlogin a")
    .remove();

  // プログレススピナーを表示
  $(".jquery-ui-dialog-onlogin p#confirm-msg")
    .empty()
    .append(spinner.el);

  // ローディング中のメッセージを生成
  $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm")
    .append('<br/><br/>')
    .append('<div id="pokemon">分析中 ...</div>')
    .append('<br/><br/>')
    .append('<div id="monsterball"></div>');

  return origin_content;
}

function afterCallWithPlotAll(origin_content) {
  // バブルチャートをaddしたダイアログを閉じる
  $("#onlogin-dialog-confirm").dialog('close');

  // ダイアログの内容を元に戻す
  $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").html("");
  $(".jquery-ui-dialog-onlogin div#onlogin-dialog-confirm").html(origin_content);

  // 進捗カウンタをリセット
  prcnt_all_cntr = 0;
}

