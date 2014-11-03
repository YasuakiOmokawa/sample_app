// リクエスト完了時に、結果をキャッシュする

// ajaxリクエスト格納
var request;

// バブルチャート用データのリクエスト（非同期）
var cacheResult = function(data, async, type, analyzetype, kwdslen, elm_txt) {
// var cacheResult = function(kwds_len, data, async, elm_txt, type) {

  // 返却データ
  var rdata;

  // ページ遷移先の設定
  var userpath = gon.narrow_action;

  var params = {
    r_obj : JSON.stringify(data),          // バブルチャート用キャッシュ対象データ
    from : $('#from').val(),
    to : $('#to').val(),
    analyze_type : analyzetype             // 全体分析か個別分析か
  };

  if (analyzetype == 'kobetsu') {

    var kobetsu_params = {
      act : elm_txt,
      cv_num : $('input[name="cv_num"]').val(),
      kwds_len : kwdslen             // キャッシュ用ユニークキー
    };

    $.extend(true, params, kobetsu_params);
  }

  // ajaxリクエストの生成
  request = $.Deferred(function(deferred) {
    $.ajax({
      url: userpath,
      async: async,
      type: type,
      dataType: "json",
      scriptCharset: 'utf-8',
      tryCount: 0,
      // timeout: 2000, // 単位はミリ秒
      retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
      // バブルチャート用データ取得用のパラメータ
      data: params,
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

  request.done(function(data, textStatus, jqXHR) {

    console.log( 'ajaxデータ転送成功!');

    rdata = JSON.parse(data.homearr);

    request = '';
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

  });

 return rdata;
}
