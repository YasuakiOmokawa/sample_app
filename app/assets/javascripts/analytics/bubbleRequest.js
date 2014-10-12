// バブルチャート取得ページ項目の絞り込みオプション
var opts_cntr = 0;
var opts = [
  'all',
  'pc',
  // 'sphone',
  // 'mobile',
  // 'new',
  // 'repeat'
];

// バブルチャート描画用のデータオブジェクト
var r_obj = {};

// バブルチャート表示リクエストの処理開始、完了フラグ
// 0: 未処理 1: 処理中 2: 処理終了
var bbl_shori_flg = 0;

// ajaxリクエスト格納
var request;

// バブルチャート用データのリクエスト（非同期）
function callExecuter(elem) {

  // ajax二重リクエストの防止
  if (request) {
    $("span#errormsg").html('バブルチャートの重複リクエストはできません。処理完了までお待ちください');
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

  // 絞り込みオプションを文字列へ変換
  var opt = opts[opts_cntr];
  var opt_txt = String(opt);

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

          // 表示項目のリセット
          $('#gp').replaceWith('<div id="gp" style="z-index: 1;"></div>');
          $('#legend1b').empty();
          $('#errormsg').empty();

          // ローディング画面の表示
          $('#gp').plainOverlay('show', {opacity: 0.2});
          $('div#info').plainOverlay('show', {opacity: 0.2, progress: false});
        }
      },
      data: {
        from : $('#from').val(),
        to : $('#to').val(),
        cv_num : $('input[name="cv_num"]').val(),
        shori : $('input[name="shori"]').val(),
        act : elm_txt, // 取得するページ項目
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

  // 並列リクエストだとアナリティクスAPIの割り当て制限エラーに引っ掛かるので逐次リクエストへ変更。
  request.done(function(data, textStatus, jqXHR) {

    console.log( 'ajax通信成功!');

    // グラフ描画用のデータをマージ
    var r_obj_tmp = JSON.parse(data.homearr);
    $.extend(true, r_obj, r_obj_tmp);

    // 項目名、フィルタ名の取得
    var page_fltr_wd = data.page_fltr_wd;
    var page_fltr_opt = data.page_fltr_opt;

    // カウンタを進める
    opts_cntr++;

    // フィルタリングオプションの配列が無くなるまでajaxを実行
    if (opts_cntr <= opts.length - 1) {

      // リクエストを処理中
      bbl_shori_flg = 1;
      callManager(bbl_shori_flg); // システム動作継続のため、リクエスト変数をリセット

      console.log( String(page_fltr_opt) + ' フィルタのajax通信が成功。処理を継続します');

      // ajaxを再実行
      callExecuter(page_fltr_wd);
    }
    else {

      // リクエストを処理終了
      bbl_shori_flg = 2;
      callManager(bbl_shori_flg);

      console.log('ページ絞り込み名 :' + page_fltr_wd);

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
  });

  // ajax失敗時の処理
  request.fail(function(jqXHR, textStatus, errorThrown) {
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
  });

  // ajax通信終了時に常に呼び出される処理
  request.always(function() {

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
    }
  });
}

// 二重送信防止のため、リクエストが未処理以外のときは送信リクエスト変数をリセットする
function callManager(flg) {

  if (flg != 0) {
    request = '';
  }
}
