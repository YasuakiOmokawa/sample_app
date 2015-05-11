// バブルチャート表示リクエストの処理開始、完了フラグ
// 0: 未処理 1: 処理中 2: 処理終了
var bbl_shori_flg = 0;

// ページ全体ローディング中のカウンタ
var prcnt_all_cntr = 0;

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

// バブルチャート取得関数
function requestPartsData(elem, return_obj, req_opts, shaped_idxarr) {

  console.log( 'ajax通信開始!');

  // ページ遷移先の設定
  var
    userpath = gon.narrow_action,
    opts = [],
    dev, usr, kwd,
    opts_cntr = 0;

  // 表示項目のリセット
  $('#errormsg').empty();
  plotGraphHome([ [0,0,1,{color: '#FFFFFF'}] ], []);
  resetHome('div#gh');

  // ローディングモーションを表示
  setLoadingMortion('div#gh', req_opts);

  // オプションキーワードを生成
  var kwd_opts = setKwds(elem, userpath);

  // オプション配列を生成
  setOpts(opts, kwd_opts);

  // キャッシュ用ユニーク文字数を格納
  var kwd_strgs = createCacheKeyNum(kwd_opts);
  req_opts.kwd_strgs = kwd_strgs;

  // キャッシュ済データを取得
  var data;
  var c_obj = cacheResult(data, false, 'GET', 'kobetsu', kwd_strgs, elem);

  // キャッシュ済データがあるか？
  if (c_obj) {

    // データマージ
    $.extend(true, shaped_idxarr, c_obj);
    req_opts.cache_get = true;
    req_opts.finished = true;

  } else {

    // ajax処理中
    bbl_shori_flg = 1;

    var tmp_obj = {};

    // データリクエストを実行
    callExecuter(elem, opts, userpath, opts_cntr, return_obj, tmp_obj, kwd_strgs, req_opts);
  }
}

// バブルチャートをオーバーレイ
function addOverlay(dom, req_opts) {

  $(dom).plainOverlay(
    'show',
    {
      opacity: 0.2,
      progress: function() {
        var target = $('<div id="guardian"></div>'
            + '<div id="daemon" style="white-space:pre;">'
                + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
                + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
                + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
                + '<br>' // 位置調整のため、jp_page_name より大きい全角空白を詰める
                + req_opts.jp_page_name + '<br>分析中<br><span></span>'
            + '</div>');
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
function resetHome(dom) {

  var id = dom.split('#');

  $(dom).replaceWith('<div id="' + id[1] + '" style="z-index: 1;"></div>');
  $('#errormsg').empty();
}

function resetHomeRanking(dom) {
  $(dom).empty();
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
      // ホーム画面で絞り込める項目のみを記載
      from : $('#from').val(),
      to : $('#to').val(),
      cv_num : $('input[name="cv_num"]').val(),
      shori : $('input[name="shori"]').val(),
      act : elem // 取得するページ項目
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

function createAjaxRequest(params) {

  var request = $.Deferred(function(deferred) {
    $.ajax({
      url: params.userpath,
      // timeout: 2,
      type:'GET',
      dataType: "json",
      tryCount: 0,
      retryLimit: 3, // 2回までリトライできる（最初の実施も含むため）
      // バブルチャート用データ取得用のパラメータ
      data: {
        from : $('#from').val(),
        to : $('#to').val(),
        cv_num : $('input[name="cv_num"]').val(),
        shori : $('input[name="shori"]').val(),
        act : params.elm_txt,             // 取得するページ項目
        dev : params.filter.dev,                 // デバイス
        usr : params.filter.usr,                   // 訪問者
        kwd : params.filter.kwd,                 // キーワード
      },
      error: function(xhr, ajaxOptions, thrownError) {

        // 内部エラーが発生したら表示
        if (xhr.status == 503) {
          $("span#errormsg").html('サーバーが一時的に応答不能となっています。<br>時間を置いてページを再読み込みしてください。<p/>');
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
  return request;
}

function createFilter(v) {
  return {
    dev: String(v.dev), // undefined の場合はサーバ側でall を指定する
    usr: String(v.usr), // undefined の場合はサーバ側でall を指定する
    kwd: String(v.kwd) === "undefined" ? 'nokwd' : String(v.kwd)
  };
}

// バブルチャート用データのリクエスト（非同期）
function callExecuter(elm_txt, opts, userpath, opts_cntr, return_obj, tmp_obj, kwd_strgs, req_opts) {

  // ajaxリクエストの生成
  var requests = [];
  if (bbl_shori_flg == 1) {

    var parallel_limit = opts_cntr + 3; // 並列処理数
    while (opts_cntr < parallel_limit) {
      var req_params = {
        filter: createFilter( opts[opts_cntr] ),
        userpath: userpath,
        elm_txt: elm_txt
      };
      requests.push( createAjaxRequest(req_params) );
      opts_cntr++;
      if (opts_cntr > opts.length - 1) {
        break;
      }
    }
  }

  if (requests) {

    $.when.apply($, requests).done(function() {

      var page_fltr_wd;
      console.log( 'ajax通信成功!');

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

        console.log('ajax処理を継続します');

        // ページ個別の進捗を算出
        var prcnt = calcProgress(opts_cntr, opts.length);

        // 画面に進捗を表示
        displayProgress('#daemon span', prcnt);

        // ajax処理を再実行
        callExecuter(page_fltr_wd, opts, userpath, opts_cntr, return_obj, tmp_obj, kwd_strgs, req_opts)
      } else {

        // リクエストを処理終了
        bbl_shori_flg = 2;

        console.log('ページ絞り込み名 :' + page_fltr_wd);

        // ローディング完了テキストを表示
        $('#daemon span').text('complete!');

        // グラフ描画用のデータを最終マージ
        $.extend(true, return_obj, tmp_obj);

        req_opts.finished = true;

      }
    })

    // ajax失敗時の処理
    .fail(function(jqXHR, textStatus, errorThrown) {
      console.log( 'ajax通信失敗!通信を中断します');
      console.log(errorThrown);

      if (errorThrown == 'timeout') {
        $("span#errormsg").html('リクエストがタイムアウトしました。時間を置いて再度実行してください。');
      } else {
        $("span#errormsg").html('エラーが発生しました。再ログインしてください。<br>解消されない場合、下記のエラーコードをお控えのうえ、担当者までお問い合わせください。<br>エラーコード : '+ errorThrown );
      }

      // 失敗したら処理終了
      bbl_shori_flg = 2;
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


// 処理完了時のリセット処理
function afterCall(dom) {
  // ローディングアニメーションのリセット
  $(dom).plainOverlay('hide');

  // リクエスト実行時のエラーメッセージ表示をリセット
  $('#errormsg').empty();

  // バブルチャート処理フラグをリセット
  bbl_shori_flg = 0;

}

function getMarkTarget(dom, page) {
  return  target = dom + ' a.' + page;
}

function addMarkTab(target, replace) {
  $(target).after(replace);
}

function createMarkTab(target) {
  return replace = '<div class="' + $(target).attr('class') + '">' + $(target).html() + '</div>';
}

function isEndTab(page, target) {
  if (page == 'social') {
    end_target = target + ' div';
    $(end_target).attr('id', 'ed');
  }
}

function hideSelectedTab(target) {
  $(target).hide();
}

function removeAllMark(dom) {
  var target = dom + ' div';
  $(target).remove();
}

function showAllTab(dom) {
  var target = dom + ' a';
  $(target).show();
}

function TabMark(dom, page_name) {

  var target = getMarkTarget(dom, page_name);
  var tab = createMarkTab(target);

  showAllTab(dom);

  removeAllMark(dom);

  addMarkTab(target, tab);

  isEndTab(page_name, dom);

  hideSelectedTab(target);
}

// バブル作成用にページ下部のタブリンクに埋め込む関数
function bubbleCreateAtTabLink(page_name) {

  if (bbl_shori_flg === 1) {
    $("span#errormsg").html('現在実行中のリクエストが完了してからもう一度お試しください。');
    return;
  }

  // 返り値データ
  var
    idxarr = [],
    shaped_idxarr = [],
    req_opts = {},
    element = parseElem(page_name);
    element_class = 'a.' + element;

  // ページ名（日本語名）
  req_opts.jp_page_name = $('#pnt').find(element_class).text();

  // タブ関連処理
  TabMark('div#pnt', element);

  createBubbleWithParts(shaped_idxarr, element, req_opts);

  createBubbleParts(element, idxarr, req_opts, shaped_idxarr);

  shapeBubbleParts(idxarr, shaped_idxarr, req_opts);

  cacheShapedBubbleParts(req_opts, element, shaped_idxarr, req_opts);
}

// 生成されたパーツを使ってバブルチャートを作成
function createBubbleWithParts(shaped_idxarr, page_name, req_opts) {

  // 返り値データをポーリング
  var timerID = setInterval( function(){
    if (Object.keys(shaped_idxarr).length != 0) {
      if (shaped_idxarr[0] != 'not_cved') {
        var plots = [];

        createGraphPlots(shaped_idxarr, plots);
        plotGraphHome(plots, shaped_idxarr);
        afterCall('div#gh');
        setRange();
      } else {
        addWhenNotCved();
      }
      clearInterval(timerID);
      timerID = null;
    }

  },100);
}

// バブル作成用のパーツを生成する関数
function createBubbleParts(page_name, idxarr, req_opts, shaped_idxarr) {

  var return_obj = {};

  requestPartsData(page_name, return_obj, req_opts, shaped_idxarr);

  // 返り値データをポーリング
  var timerID = setInterval( function(){
    if( typeof req_opts.finished != 'undefined') {

      if(Object.keys(return_obj).length != 0){
        // データ項目一覧セット
        setDataidx(return_obj, page_name, idxarr);
      } else {
        if (req_opts.cache_get != true) {
          shaped_idxarr.push('not_cved');
        }
      }
      clearInterval(timerID);
      timerID = null;
   }
  },100);
}

function shapeBubbleParts(idxarr, shaped_idxarr, req_opts) {
  var timerID = setInterval( function(){
    if (Object.keys(idxarr).length != 0) {
      $.extend(true, shaped_idxarr, headIdxarr(sortIdxarr(idxarr), 15));
      clearInterval(timerID);
      timerID = null;
    }
  },100);
}

function cacheShapedBubbleParts(req_opts, elm, shaped_idxarr, req_opts) {
  var timerID = setInterval( function() {
    if (Object.keys(shaped_idxarr).length != 0) {
      if (req_opts.cache_get != true) {
        cacheResult(shaped_idxarr, true, 'POST', 'kobetsu', req_opts.kwd_strgs, elm);
      }
      clearInterval(timerID);
      timerID = null;
    }
  }, 100);
}

function addWhenNotCved() {
  afterCall('div#gh');
  $("span#errormsg").html('アナリティクスのデータが分析対象に達していません。<br>CVがある期間を指定して再実行してください。');
  plotGraphHome([ [0,0,1,{color: '#FFFFFF'}] ], []); // ダミー表示
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

// ローディングモーションを設定
function setLoadingMortion(dom, req_opts) {

  // プログレススピナーを生成
  var spinner = createSpinner();

  // バブルチャートをオーバーレイ
  addOverlay(dom, req_opts);

  // プログレススピナーを表示
  $('#guardian').append(spinner.el);

}

function replaceAll(expression, org, dest){
    return expression.split(org).join(dest);
}

// ホーム画面でハッシュを変更させる
function changeLocationHash(page) {
  location.hash = encodeURIComponent(page + createHomeURIBaseParams());
}

function createHomeURIBaseParams() {
  var params = "";
  jQuery.each(setHomeURIBaseParams(), function (key, val) {
    params += '#' + val;
  });
  return params;
}

function setHomeURIBaseParams() {
  var params = {}, id = '';
  params.from = replaceAll($('#from').val(), '/', '-');
  params.to = replaceAll($('#to').val(), '/', '-');
  params.cv_num = $('input[name="cv_num"]').val();
  if ( id = $('input[name="custom_file_id"]').val() ) {
    params.custom_file_id = id;
  }
  return params;
}


function getLocationHashPage() {
  var params = decodeURIComponent(location.hash).split("#");
  return params[1];
}

function setAnchorParams(params) {
  $('#from').val(replaceAll(params.from, '-', '/'));
  $('#to').val(replaceAll(params.to, '-', '/'));
  $('input[name="cv_num"]').val(params.cv_num);
  $('select[name="cvselect"]').val(params.cv_num);
}

// ホーム画面でハッシュが変更されたときのイベント
function locationHashChanged() {
var params = pushLocationHash(decodeURIComponent(location.hash).split("#"));
console.log("location.hash is " + params)
setAnchorParams(params);
bubbleCreateAtTabLink(params.category);
}

function pushLocationHash(d) {
  var obj = {};
  obj.category = d[1], obj.from = d[2], obj.to = d[3], obj.cv_num = d[4];
  if (d[5]) {
    obj.file_id = d[5];
  }
  return obj;
}


$(document).ready(function() {

  // 分析カテゴリがクリックされたときのイベント
  var anlyz_category = '#pnt a';
  $(anlyz_category).click(function() {
    var page = $(this).attr('class');
    changeLocationHash(page);
  });

  // hashchangeハンドラの定義
  window.onhashchange = locationHashChanged;

});
