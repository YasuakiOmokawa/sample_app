// バブルチャートの生成(main function)
function plotGraphHome(arr, idxarr) {
  // バブル（散布図）チャート相関グラフ
  // x軸, y軸, 大きさ(radius), 項目名　の順に表示

  // リプロット用にarr をグローバルオブジェクトとして確保
  arr_for_replot = $.extend(true, {}, arr);

  // グラフ描画対象
  var graph_position = 'fm_graph';

  // グラフ描画オプション
  var options = {
    seriesDefaults: {
      renderer: jQuery.jqplot.BubbleRenderer,
      rendererOptions: {
        showLabels: false,
        autoscaleBubbles: false, // サイズはグラフデータのradius から算出(単位: pixel)
        shadow: false,
      },
    },
    // グラフ幅の調整
    gridPadding: { top: 1, bottom: 1, left: 1, right: 1 },
    series: [],
    axesDefaults: {
      numberTicks: 3,
      tickOptions: {
        fontSize: '10pt',
        fontFamily: 'ヒラギノ角ゴ Pro W3',
        markSize: 0
      },
    },
    axes: {
      // 見栄えの問題で、max は101, min は -1 で調整
      xaxis: {
        // label: '変動係数',
        min: 0.0,
        max: 1.0,
      },
      yaxis: {
        // label: '相関係数',
        min: 0.0,
        max: 1.0,
      },
    },
    // 背景色に関する設定
    grid: {
      background: "transparent",
      gridLineColor: "#cccccc",
      shadow: false,
      drawGridlines: true,
      drawBorder: false,
    },
  };

  var $rank_target = $('#rank');

  // 項目一覧へ要素を追記
  addRanking(idxarr, $rank_target);

  // jqplot描画後に実行する操作（jqplot描画前に書くこと）
  resetPostDrawHooks();
  var homePostDraw = function homePostDraw(graph) {
    // 目盛り線のみ残して目盛りの値は削除
    var selcts = [ $('.jqplot-xaxis-tick'), $('.jqplot-yaxis-tick') ];
    for (var i=0; i<selcts.length; i++) {
      $(selcts[i][0]).text('');
      $(selcts[i][1]).text('');
      $(selcts[i][2]).text('');
    }
  };
  $.jqplot.postDrawHooks.push(homePostDraw);

  var graph = jQuery . jqplot(graph_position, arr, options);

  // ウインドウリサイズが発生したらイベントを発生
  var timer = false;
  $(window).off('resize').on('resize', function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
      console.log('home graph resized');
      graph.replot();
    }, 200);
  });

  // ブロック項目をホバーしたらプロットへデータ表示
  $rank_target.on({
      'mouseenter': function() {
        replotHome($(this));
        showTooltip($(this));
      },
      'mouseleave': function() {
        replot_options = {
          series: []
        };
        replot_options.data = arr_for_replot;
        graph.replot(replot_options);
      }
  }, 'a');

  // ブロックをクリックしたら詳細へ遷移する
  $rank_target.on('click', 'a', function() {
    // detail_anlyzへのパスを取得
    var path = $("#detail_user_path").text();
    var query = new Query();

    // dataブロックの値から、詳細分析用に絞り込みパラメータを取得
    //　曜日、デバイス、ユーザー、その他キーワード
    var datas = $(this).data();
    var _datas = {};
    for( i in datas) {
      if (i.match(/^dayType$|devfltr|usrfltr|kwdfltr|^metrics$/)) {
        if (i == "kwdfltr" && datas[i] != "nokwd") {
          switch (datas.category) {
          case 'referral':
            datas[i] = datas[i] + 'r';
            break;
          case 'social':
            datas[i] = datas[i] + 'l';
            break;
          }
        }
        _datas[i] = datas[i];
      }
    }
    // 詳細遷移のためのパスを取得
    var to_detail = path + "?" + query.getQuery() + "&" + jQuery.param(_datas);
    var detail_url = location.origin+to_detail;
    // console.log("detail  is "+detail_url);
    window.wiselinks.page.load(detail_url, "@data-role", 'partial');
  });

  // スピナーの起動
  $rank_target.on('click', 'a', function() {
    $('#loading').removeClass('hide');
    $('#spinner').removeClass('hide');
    $('#now-loading-dummy').removeClass('hide');
  });

  // ホームグラフをリプロットする
  function replotHome(target) {

    var origin_arr = $.extend(true, {}, arr_for_replot), // 参照渡しだとバグる。
      p_color = setBubbleColor(target.data('vari'), target.data('corr')),
      addopt = [target.data('vari'), target.data('corr'), 30, p_color];
    var add_options = {
      series: [],
    };

    // 選択したものは拡大して表示させる
    origin_arr[0].push(addopt);
    add_options.data = origin_arr;

    // 再描画を実行
    // jqplot の replot関数は、追加のオプションを設定すると
    // 追加部分「だけ」変更してくれるので余計な記載をせずに済む。
    graph.replot(add_options);
  }
}

function createGraphPlots(idxarr, arr) {

  var plot_color = {}, tmp_arr = [];

  for (i=0; i < idxarr.length; i++) {

    var x = idxarr[i]['vari'];
    var y = idxarr[i]['corr'];
    plot_color = setBubbleColor(x, y);
    tmp_arr[i] = [ x, y, 8, plot_color];       // グラフx軸, グラフy軸, バブルの大きさ, バブルの色　で指定
  }
  arr.push(tmp_arr);
}

function isVariationOverLimit(vari) {
  var VARIATION_LIMIT = 1;
  if (vari > VARIATION_LIMIT) {
    return 1;
  } else {
    return vari;
  }
}

function headIdxarr(idxarr, limit) {
  var headed_obj = [];

  for (var idx in idxarr) {

    headed_obj[idx] = idxarr[idx];

    // 表示件数の上限をlimit 件数へ制限
    if (idx >= limit -1) {
      return headed_obj;
    }
  }
  return headed_obj;
}

function setInfoForDetailUI(datas) {

  // 詳細画面で表示するためのデータを保持
  // カテゴリ、曜日別、デバイス、ユーザー、その他条件、平均値、項目名、目標値、gap(desire - avg)
  var _datas = {};

  // データの抽出
  _datas.category = $(document.getElementById(datas.category)).text();
  _datas.dayTypeJp = datas.dayTypeJp;
  _datas.devfltr = devTnsltENtoJP(datas.devfltr);
  _datas.usrfltr = usrTnsltENtoJP(datas.usrfltr);
  _datas.kwdfltr = kwdTnsltENtoJP(datas.kwdfltr);
  _datas.metricsAvg = datas.metricsAvg;
  _datas.metricsJp = datas.metricsJp;
  _datas.desire = datas.desire;
  _datas.gap = RoundValueUnderOne(datas.desire - datas.metricsAvg);
  _datas.metricsFormat = datas.metricsFormat;

  // データを格納
  sessionStorage.setItem( "data_for_detail", JSON.stringify(_datas) );
  return _datas;
}

function chkDayType(d) {
  if (typeof d === 'undefined') {
    return '全日';
  } else {
    return d;
  }
}

// 項目一覧へ要素を追記
function addRanking(idxarr, $target) {

  // 項目一覧へ表示する項目番号
  var counter = 0;

  // 項目一覧へ表示する文字列
  var caption;

  // 絞り込み情報の保持
  var text;

  // 項目一覧データを追記
  idxarr.some(function(value){

    counter = counter + 1;

    var metrics = addGraphicItem(value['jp_metrics']);
    var metrics_format = metricsFormat(metrics);

    $target
    .append(
      $('<li>')
      .append(
        $('<a>')
          .attr({
            "href": 'javascript:void(0)',
            "title": counter,
            'data-pri': value['pri'],
            'data-corr': value['corr'],
            'data-corr-sign': value['corr_sign'],
            'data-metrics': metrics,
            'data-metrics-format': metrics_format,
            'data-metrics-jp': value['jp_metrics'],
            'data-day-type-jp': chkDayType(value['day_type_jp']),
            'data-day-type': value['day_type'],
            'data-metrics-avg': value['metrics_avg'],
            'data-metrics-stddev': value['metrics_stddev'],
            'data-vari': value['vari'],
            'data-devfltr': value['dev_fltr'],
            'data-usrfltr': value['usr_fltr'],
            'data-kwdfltr': value['kwd_fltr'],
            "name": value['pagelink'],
            'data-category': value['category'],
            'class': 'data-contents',
            'data-desire': value['desire'],
            'data-target': "@data-role",
            'data-push': "partial",
          })
          .text(counter)
      )
    );
  });

  // 終端処理
  $target.append($('<br class="clear">'));
}

// バブル色の指定
function setInitialBubbleColor() {
  return {color: '#7f7f7f'};
}

var setBubbleColor = function(x, y) {
    var label;
    var x = Number(x);
    var y = Number(y);
    var YREFERENCE = 0.5
    var XREFERENCE = 0.5

    if (x >= XREFERENCE && y >= YREFERENCE) {
        label = {color: '#c00000'};
        // console.log('color is red');
    }
    else if ( (x >= XREFERENCE && y <= YREFERENCE) || (x <= XREFERENCE && y >= YREFERENCE) ) {
        label = {color: '#ffc000'};
        // console.log('color is yellow');
    }
    else if (x <= XREFERENCE && y <= YREFERENCE) {
        label = {color: '#0070c0'};
        // console.log('color is blue');
    }
    return label;
}

function calcCorrPri(data) {
  return data * 2;
}

function calcPriorityData(obj) {
  if (obj.corr >= 0.5 && obj.vari >= 0.5) {
    return true;
  } else {
    return false;
  }
}

// データ項目一覧の設定
var setDataidx = function(obj, wd, idxarr) {

  var homearr = $.extend(true, {}, obj), // 参照渡しだとバグる。
    fltr_wd = wd,
    tmp_obj = {};

  for (var i in homearr[fltr_wd]) {

    // 絞り込みオプションの取り出し
    var fltr = String(i).split('::'),    // デバイス::訪問者::キーワード::日付タイプ
      dev_fltr = fltr[0],
      usr_fltr = fltr[1],
      kwd_fltr = fltr[2],
      day_type = fltr[3],
      tmp = homearr[fltr_wd][i];

    for (var j in tmp) {
      var
        ar = {},
        jp = tmp[j].jp_caption.split(';;');

      ar['corr'] = tmp[j].corr;
      ar['vari'] = isVariationOverLimit(tmp[j].vari);
      ar['pri'] = calcCorrPri(ar['corr']) + ar['vari'] + calcPriorityData(ar);
      ar['corr_sign'] = tmp[j].corr_sign;
      ar['jp_metrics'] = jp[0];
      ar['day_type_jp'] = jp[1];
      ar['day_type'] = day_type;
      ar['metrics_avg'] = tmp[j].metrics_avg;
      ar['metrics_stddev'] = tmp[j].metrics_stddev;
      ar['dev_fltr'] = dev_fltr;
      ar['usr_fltr'] = usr_fltr;
      ar['kwd_fltr'] = kwd_fltr;
      ar['category'] = fltr_wd;
      ar['desire'] = tmp[j].desire;
      idxarr.push(ar);
    }
  }
}

function isReallyNaN(x) {
  return x !== x;    // xがNaNであればtrue, それ以外ではfalse
}


// 優先順位の降順でソート
// > がマイナスリターン。。降順、< がプラスリターンで昇順
function sortIdxarr(idxarr) {

  for(var i in idxarr) {
    if (isReallyNaN(parseFloat(idxarr[i].pri))) {
      delete idxarr[i];
    }
  }

  var idxarr = idxarr.sort(function(_a,_b) {
    // 第一ソートキーは相関係数
    var a = parseFloat(_a.corr), b = parseFloat(_b.corr);
    if (a > b) return  -1;
    if (a < b) return  1;
    if (a == b) {
      // 第二ソートキーは変動係数
      var a = parseFloat(_a.vari), b = parseFloat(_b.vari);
        if (a >= b) return  -1;
        if (a < b) return  1;
    }
  });
  console.log(idxarr);
  return idxarr;
}

// グラフ項目の絞り込みパラメータを設定
function addGraphicItem(data) {

  switch (data) {
    case 'ページビュー数':
      return 'pageviews';
      break;
    case 'ページ/セッション':
      return 'pageviews_per_session';
      break;
    case 'セッション':
      return 'sessions';
      break;
    case '直帰率':
      return 'bounce_rate';
      break;
    case '新規セッション率':
      return 'percent_new_sessions';
      break;
    case 'ユーザー':
      return 'users';
      break;
    case '平均セッション時間':
      return 'avg_session_duration';
      break;
    case 'リピーター':
      return 'repeat_rate';
      break;
  }
}

function metricsFormat(value) {
  switch(value) {
    case 'bounce_rate':
    case 'repeat_rate':
    case 'percent_new_sessions':
      return 'percent';
      break;
    case 'avg_session_duration':
      return 'time';
      break;
    default:
      return 'number';
      break;
  }
}

// 項目一覧に表示する流入元データを日本語へ変換(デバイス)
function devTnsltENtoJP(d) {

  // 変換表
  var options = {
    pc: 'パソコン',
    sphone: 'スマートフォン',
    mobile: 'モバイル',
    all: '全デバイス',
  };

  var wd = String(options[d]) === "undefined"? String(options['all']) : String(options[d]);
  return wd;
}

// 項目一覧に表示する流入元データを日本語へ変換(訪問者)
function usrTnsltENtoJP(d) {

  // 変換表
  var options = {
    new: '新規',
    repeat: 'リピーター',
    all: '全訪問者',
  };

  var wd = String(options[d]) === "undefined"? String(options['all']) : String(options[d]);
  return wd;
}

function kwdTnsltENtoJP(d) {

  var wd;
  if (d === 'nokwd' ) {
    wd = '参照元なし';
  } else {
    wd = '参照元: '+d;
  }
  return wd;
}

function signTnsltENtoMark(d) {
  if (d === 'plus') {
    return '+';
  } else {
    return '-';
  }
}

function showTooltip(contents) {

  // data プロパティの取得
  var datas = contents.data();

  // 詳細表示データの保持
  var _datas = setInfoForDetailUI(datas);

  var position = (function() {
    if (datas.vari >= 0.5) {
      return 'hvr_l';
    } else {
      return 'hvr_r';
    }
  }());

  var prefix = (function() {
    if (_datas.gap >= 0) {
      return '+';
    } else {
      return ' - ';
    }
  }());

  var gap = '（'+prefix+tickFormatter(_datas.metricsFormat, Math.abs(_datas.gap) )+'）';

  $('#fm_graph')
  .prepend(
    $('<div id="'+position+'">')
    .append(
      $('<dl id="tgt">')
      .append(
        $('<dt>')
        .text( datas.metricsJp )
      )
      .append(
        $('<dd>')
        .text( tickFormatter(datas.metricsFormat, datas.desire) )
        // .text("1,234")
        .append(
          $('<span id="gp">')
          .text(gap)
          // .text('(+123)')
        )
      )
    )
    .append(
      $('<ul id="bottom">')
      .append($("<li>").append(
        $("<dl>")
        .append($("<dt>").text("流入元"))
        .append( $("<dd>").text( _datas.category ) )
        )
      )
      .append($("<li>").append(
        $("<dl>")
        .append($("<dt>").text("曜日"))
        .append($("<dd>").text( _datas.dayTypeJp ) )
        )
      )
      .append($("<li>").append(
        $("<dl>")
        .append($("<dt>").text("デバイス"))
        .append($("<dd>").text( _datas.devfltr ) )
        )
      )
      .append($("<li>").append(
        $("<dl>")
        .append($("<dt>").text("ユーザー"))
        .append($("<dd>").text( _datas.usrfltr ) )
        )
      )
      .append($("<li>").append(
        $("<dl>")
        .append($("<dt>").text("その他条件"))
        .append($("<dd>").text( _datas.kwdfltr ) )
        )
      )
    )
  );
}
