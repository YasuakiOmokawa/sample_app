// バブルチャート表示リクエストの処理開始、完了フラグ
// 0: 未処理 1: 処理中 2: 処理終了
var bbl_shori_flg = 0;

function locationHashChanged(category) {
  console.log("ホーム分析開始!");

  // ローディングモーションを表示
  $('#loading').removeClass('hide');
  $('#spinner').removeClass('hide');

  var params = (function() {
    if (category == "atics_s") {
      return createParameterWithSessionStorage();
    } else {
      return createParameterWithLocationHash(category);
    }
  }());

  // バブル作成用にページ下部のタブリンクに埋め込む関数
  (function bubbleCreateAtTabLink() {

    if (bbl_shori_flg === 1) {
      addErrorMessage('現在実行中のリクエストが完了してからもう一度お試しください。');
      return;
    }

    // 返り値データ
    var
      idxarr = [],
      shaped_idxarr = [],
      req_opts = {};

    // ページ名（日本語名）
    req_opts.jp_page_name = $(document
      .getElementById(params.for_anlyz.category)).text();

    // タブ関連処理
    // TabMark('div#pnt', element);

    // 生成されたパーツを使ってバブルチャートを作成
    (function createBubbleWithParts() {

      // 返り値データをポーリング
      var timerID = setInterval( function(){
        if (Object.keys(shaped_idxarr).length != 0 ) {

          // データがキャッチされた後の処理
          if (shaped_idxarr[0] != 'not_cved') {
            var plots = [];

            createGraphPlots(shaped_idxarr, plots);
            plotGraphHome(plots, shaped_idxarr);
            // afterCall('div#gh');
            // setRange();
          } else {
            // データ不足で分析できない旨を表示
            addWhenNotCved();
          }
          // ポーリング終了処理
          clearInterval(timerID);
          timerID = null;
        }
      },100);
    }());

    //  バブルチャートのデータを作成
    (function createBubbleParts() {
      var return_obj = {};

      // バブルチャート取得関数
      (function requestPartsData() {

        console.log( 'バブルチャートリクエストを開始!');

        // ページ遷移先の設定
        params.userpath = $("#home_anlyz_user_path").text();
        var
          opts = [],
          dev, usr, kwd,
          opts_cntr = 0;

        // オプションキーワードを生成
        // ページ項目に合わせた絞り込みキーワードを取得する
        var kwd_opts = (function setKwds() {

          // 返り値
          var dt = [];

          // ページ項目に合わせた絞り込みキーワードを取得する
          // この時点では絞り込みオプションを指定しない
          console.log( '絞り込み用キーワード取得対象 : '
            + params.for_anlyz.category);
          console.log( '絞り込み用キーワード取得処理の開始');

          $.ajax({
            url: params.userpath,
            async: true,
            dataType: 'json',
            data: params,
          })
          .done(function(data, textStatus, jqXHR) {
            var d = JSON.parse(data.homearr);
            console.log( '絞り込み用キーワード取得完了');
            console.log(d);
            $.extend(true, dt, d);
          })
          .fail(function(jqXHR, textStatus, errorThrown) {
            addErrorMessage('絞り込み用キーワード取得エラーが発生しました： '
              + String(errorThrown));
          })
          .always(function() {
            console.log('絞り込み用キーワード取得処理の終了');
          });

          return dt;
        }());

        // オプション配列を生成
        setOpts(opts, kwd_opts);

        // キャッシュ用ユニーク文字数を格納
        var kwd_strgs = createCacheKeyNum(kwd_opts);
        req_opts.kwd_strgs = kwd_strgs;

        // ajax処理中
        bbl_shori_flg = 1;

        var tmp_obj = {};

        // データリクエストを実行
        (function callExecuter() {

          // ajaxリクエストの生成
          var requests = [];
          if (bbl_shori_flg == 1) {

            var parallel_limit = opts_cntr + 3; // 並列処理数
            while (opts_cntr < parallel_limit) {
              params.for_anlyz = createFilter( opts[opts_cntr] );
              requests.push( createAjaxRequest(params) );
              opts_cntr++;
              if (opts_cntr > opts.length - 1) {
                break;
              }
            }
          }

          if (requests) {

            $.when.apply($, requests).done(function() {

              var page_fltr_wd;
              console.log( 'グラフデータajax通信成功!');

              // グラフ描画用のデータをマージ
              $.each(arguments, function(k, v) {

                var r_obj_tmp = JSON.parse(v[0].homearr);
                $.extend(true, tmp_obj, r_obj_tmp);

                // 項目名、フィルタ名の取得
                page_fltr_wd = v[0].page_fltr_wd;
                var page_fltr_dev = v[0].page_fltr_dev;
                var page_fltr_usr = v[0].page_fltr_usr;
                var page_fltr_kwd = v[0].page_fltr_kwd;

                console.log('デバイス : ' + page_fltr_dev + ' 訪問者 : ' + page_fltr_usr + ' キーワード : ' + page_fltr_kwd );
              });

              // フィルタリングオプションの配列が無くなるまでajaxを実行
              if (opts_cntr <= opts.length - 1) {

                console.log('グラフデータajax処理を継続します');
                // ajax処理を再実行
                callExecuter();
              } else {

                // リクエストを処理終了
                bbl_shori_flg = 2;

                console.log('分析カテゴリ :' + page_fltr_wd);

                // ローディング完了テキストを表示
                // $('#daemon span').text('complete!');

                // グラフ描画用のデータを最終マージ
                $.extend(true, return_obj, tmp_obj);

                req_opts.finished = true;
              }
            })
            // ajax失敗時の処理
            .fail(whenAjaxFail())
            // ajax通信終了時に常に呼び出される処理
            .always(function() {
              // リクエスト処理が終了した場合に実行される
              if (bbl_shori_flg == 2) {
                console.log( 'ajax通信終了!');
              }
            });
          }
        }());
      }());

      // 返り値データをポーリング
      var timerID = setInterval( function(){

        // データがキャッチされた後の処理
        if( typeof req_opts.finished != 'undefined') {

          if(Object.keys(return_obj).length != 0){
            // データ項目一覧セット
            setDataidx(return_obj, element, idxarr);
          } else if (req_opts.cache_get != true) {
            shaped_idxarr.push('not_cved');
          }
          // ポーリング終了処理
          clearInterval(timerID);
          timerID = null;
        }
      },100);
    }());

    // バブルチャートのデータを優先度別に上位15位まで選別
    (function shapeBubbleParts() {
      var timerID = setInterval( function(){
        if (Object.keys(idxarr).length != 0) {
          $.extend(true, shaped_idxarr, headIdxarr(sortIdxarr(idxarr), 15));
          clearInterval(timerID);
          timerID = null;
        }
      },100);
    }());

    // 選別したバブルチャートのデータをmemcachedへキャッシュする
    (function cacheShapedBubbleParts() {
      var timerID = setInterval( function() {
        if (Object.keys(shaped_idxarr).length != 0) {
          if (req_opts.cache_get != true) {

            // リクエスト完了時に、結果をキャッシュする
            (function cacheResult() {

              // ajaxリクエストの生成
              var request = $.Deferred(function(deferred) {
                $.ajax({
                  url: $("#cache_result_anlyz_user_path").text(),
                  async: true,
                  type: 'POST',
                  dataType: "json",
                  scriptCharset: 'utf-8',
                  tryCount: 0,
                  // timeout: 2000, // 単位はミリ秒
                  retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
                  data: {
                    result_obj : JSON.stringify(shaped_idxarr), // バブルチャート用キャッシュ対象データ
                    cache_key: params.for_get_request,
                  },
                  error: whenAjaxError(deferred)
                }).done(function(data, textStatus, jqXHR) {
                  deferred.resolveWith(this, [data, textStatus, jqXHR]);
                });
              }).promise();

              request.done(function(data, textStatus, jqXHR) {
                console.log( 'ajaxデータのキャッシュ成功!');
                request = '';
              })
              // ajax失敗時の処理
              .fail(whenAjaxFail());
            }());
          }
          clearInterval(timerID);
          timerID = null;
        }
      }, 100);
    }());
  }());
}

// デバイス
function getDevOpts() {
  return [
    'pc',
    'sphone',
    'mobile',
  ];
}

// 訪問者
function getUsrOpts() {
  return [
    'new',
    'repeat'
  ];
}

// パラメータの全ての組み合わせを網羅した配列を作る
function setOpts(opts, kwd_opts) {

  var dev_opts = getDevOpts();

  var usr_opts = getUsrOpts();

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

function createAjaxRequest(params) {

  var request = $.Deferred(function(deferred) {
    $.ajax({
      // url: '/hoge/fuga',
      url: params.userpath,
      // timeout: 2,
      type:'GET',
      dataType: "json",
      tryCount: 0,
      retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
      // バブルチャート用データ取得用のパラメータ
      data: params.for_anlyz,
        // from : params.params.for_anlyz.from,
        // to : params.params.for_anlyz.to,
        // cv_num : params.params.for_anlyz.cv_num,
        // shori : 1,
        // act : params.params.for_anlyz.category,  // 分析カテゴリ
        // dev : params.filter.dev,                 // デバイス
        // usr : params.filter.usr,                   // 訪問者
        // kwd : params.filter.kwd,                 // キーワード
      // error: function(xhr, ajaxOptions, thrownError) {
      error: whenAjaxError(deferred)
    }).done(function(data, textStatus, jqXHR) {
      deferred.resolveWith(this, [data, textStatus, jqXHR]);
    });
  }).promise();
  return request;
}

function whenAjaxError(deferred) {

  // callback時に渡される無名関数から、返り値を取得
  return function(xhr, ajaxOptions, thrownError) {
    // 内部エラーが発生したら表示
    if (xhr.status == 503) {
      $("#add_error_msg")
        .removeClass("hide")
        .html('サーバーが一時的に応答不能となっています。<br>時間を置いてページを再読み込みしてください。<p/>');
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
}

function whenAjaxFail() {
  return function(jqXHR, textStatus, errorThrown) {
    console.log( 'ajax通信失敗!通信を中断します');
    console.log(errorThrown);

    if (errorThrown == 'timeout') {
      addErrorMessage('リクエストがタイムアウトしました。時間を置いて再度実行してください。');
    } else {
      addErrorMessage('エラーが発生しました。再ログインしてください。'
        +'<br>解消されない場合、下記のエラーコードをお控えのうえ、担当'
        +'者までお問い合わせください。<br>エラーコード : '+ errorThrown);
    }

    // 失敗したら処理終了
    bbl_shori_flg = 2;
  }
}

function createFilter(v) {
  return {
    dev: String(v.dev), // undefined の場合はサーバ側でall を指定する
    usr: String(v.usr), // undefined の場合はサーバ側でall を指定する
    kwd: String(v.kwd) === "undefined" ? 'nokwd' : String(v.kwd)
  };
}

// 処理完了時のリセット処理
function afterCall() {
  // ローディングアニメーションのリセット
  $("#loading").addClass("hide");
  $("#spinner").addClass("hide");

  // リクエスト実行時のエラーメッセージ表示をリセット
  $('#add_error_msg')
    .addClass("hide")
    .empty();

  // バブルチャート処理フラグをリセット
  bbl_shori_flg = 0;
}

function addErrorMessage(text) {
  $("#add_error_msg")
    .removeClass("hide")
    .html(text);
}

// データ不足で分析できないときのエラー文言を表示
function addWhenNotCved() {
  $("#error_msg").removeClass("hide");
}
