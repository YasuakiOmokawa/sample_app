function createGraphPlots(idxarr, arr) {

  var plot_color = {}, tmp_arr = [], soukan, soukan_percent;

  for (i=0; i < idxarr.length; i++) {

    soukan = IsZeroSoukan(idxarr[i]['arr'][1]);
    soukan_percent = chgSoukanToPercent(soukan);

    plot_color = setBubbleColor(idxarr[i]['arr'][0], soukan_percent);

    // x, y, radius, plot_color
    // tmp_arr[i] = [idxarr[i]['arr'][0], 30, 1, plot_color];
    tmp_arr[i] = [idxarr[i]['arr'][0], soukan_percent, 1, plot_color];
  }

  arr.push(tmp_arr);
  // console.log(arr);
}

function IsZeroSoukan(v) {
  if (v == 0) {
    return 1;
  } else {
    return v;
  }
}

function chgSoukanToPercent(soukan_value) {
  var from = new Date($("#from").val());
  var to = new Date($("#to").val());
  var d =  to - from;
  var dms = 1000 * 60 * 60 * 24;
  var base_days = Math.floor(d / dms);

  if ((base_days - 1) <= 0) {
    base_days = 1;
  }

  return percent = Math.floor( (soukan_value / base_days) * 100);
}

function headIdxarr(idxarr, limit) {

  var headed_obj = [];

  if (idxarr.length < limit) {
    return idxarr;
  }

  for (var i=0; i < idxarr.length; i++) {

    headed_obj[i] = idxarr[i];

    // 表示件数の上限をlimit 件数へ制限
    if (i >= limit -1) {
      return headed_obj;
    }
  }

}

// 項目一覧データにクリックイベントを追加
function addClickEvtToInfo(target) {

  $(target).click(function(e) {

      var metrics = $(e.target).data('metrics');
      console.log('metrics : ' + metrics);

      // グラフ項目と人気ページパラメータを設定
      addNarrowParam( metrics, $('input[name="graphic_item"]'), $('#narrow_select') );

      // 絞り込みチェックボックスの値を指定
      var dp = $(e.target).data('devfltr');
      var up = $(e.target).data('usrfltr');
      console.log('dp : ' + dp);
      console.log('up : ' + up);


      $.each([dp,up], function(i, val) {
        var type,n,m;
        type = 'form[name="narrowForm"] input[value=' + val + ']';
        n = $(type).attr("name");
        m = 'form[name="narrowForm"] input[name=' + n + ']';
        $(m).val([val]);
      });

      // 絞り込みキーワードの値を設定
      var kp = $(e.target).data('kwdfltr'); // キーワード
      console.log('kp : ' + kp);

      if (kp != 'nokwd') {
        var flg; // どのページのキーワードか判別用

        // 遷移先の最後のアクション名を取得
        var p = $(e.target).attr("name");
        p = p.split('/');

        // 遷移先を判別
        switch (p[3]) {
          case 'search':
            flg = 's';
            break;
          case 'direct':
            flg = 'f';
            break;
          case 'referral':
            flg = 'r';
            break;
          case 'social':
            flg = 'l';
            break;
          default:
            flg = 'f';
        }

        // 遷移先のキーワードとページ情報を設定
        var n_wd = kp + flg;
        $('#narrow_select')
          .append($('<option>')
            .html(" ")
            .val(n_wd)
          ).val(n_wd);
      }

      // 遷移先の強調項目を設定
      $('input[name="red_item"]').val(metrics);

      // 遷移先ページタブ情報を保持
      var prev_page = String(metrics);
      $('input[name="prev_page"]').val(prev_page);
      console.log('prev_page : ' + prev_page);

      // ページ遷移
      evtsend($(e.target).closest('td'));
  });
}

// 項目一覧へ要素を追記
function addRanking(idxarr, target) {

  // 項目一覧へ表示する項目番号
  var counter = 0;

  // 項目一覧へ表示する文字列
  var caption;

  // 絞り込み情報の保持
  var text;

  // 項目一覧データを追記
  idxarr.some(function(value){

    counter = counter + 1;

    // 絞り込み情報の追加
    text = value['arr'][3].split(';;');

    // 項目一覧へ表示する文字列
    // データ指標：デバイス：ユーザー：絞り込み条件(あれば)
    caption = text[1] + ':' + devTnsltENtoJP(value['dev_fltr']) + ':' + usrTnsltENtoJP(value['usr_fltr']) + ':' + kwdTnsltENtoJP(value['kwd_fltr']);

    $(target)
    .append(
      $('<li>')
      .append(
        $('<a>')
          .attr({
            "href": 'javascript:void(0)',
            "title": counter,
            "name": value['pagelink'],
            'data-gap': value['arr'][0],
            'data-sokan': value['arr'][1],
            'data-metrics': text[1],
            'data-devfltr': value['dev_fltr'],
            'data-usrfltr': value['usr_fltr'],
            'data-kwdfltr': value['kwd_fltr']
          })
          .text(counter)
      )
    );

  });
}

// 優先順位の降順、
// 　ページ名と項目名の昇順でソート
// > がマイナスリターン。。降順、< がプラスリターンで昇順
function sortIdxarr(idxarr) {

  var idxarr = idxarr.sort(function(a,b) {
    if (a.pri > b.pri) return  -1;
    if (a.pri < b.pri) return  1;
    if (a.page > b.page) return  1;
    if (a.page < b.page) return  -1;
    if (a.name > b.name) return  1;
    if (a.name < b.name) return  -1;
  });
  return idxarr;
}

// バブル色の指定
var setBubbleColor = function(x, y) {
    var label;
    var x = parseInt(x);
    var y = parseInt(y);

    if (x >= 51 && y >= 51) {
        label = {color: '#c00000'};
        // console.log('color is red');
    }
    else if ( (x <= 50 && y >= 51) || (x >= 51 && y <= 50) ) {
        label = {color: '#ffc000'};
        // console.log('color is yellow');
    }
    else if (x <= 50 && y <= 50) {
        label = {color: '#0070c0'};
        // console.log('color is blue');
    }
    return label;
}

// データ項目一覧の設定
var setDataidx = function(obj, wd, idxarr) {

  var homearr = $.extend(true, {}, obj); // 参照渡しだとバグる。
  // var idxarr = [];
  var arr = [];
  var cnt = 0;
  var fltr_wd = wd
  var pagenm = 'div#pnt a.' + fltr_wd;   // ページ名（全体、検索、など）を取得
  var pagelink = $(pagenm).attr('path');   // ページへのリンクを取得

  for (var i in homearr[fltr_wd]) {

    // 絞り込みオプションの取り出し
    var fltr = String(i).split('::');    // デバイス::訪問者::キーワード
    var dev_fltr = fltr[0];
    var usr_fltr = fltr[1];
    var kwd_fltr = fltr[2];

    arr.push( homearr[fltr_wd][i] );
    arr[cnt].forEach( function(value) {
      var nm = value[3].split(';;');
      value[3] = fltr_wd + ';;' + value[3];

      // GAPと相関の合計値が高いものほど優先度を高くする。
      var ar = {};
      var pri = value[0] + value[1];
      ar['pri'] = pri;
      ar['arr'] = value;
      ar['name'] = nm[0];
      ar['dev_fltr'] = dev_fltr;
      ar['usr_fltr'] = usr_fltr;
      ar['kwd_fltr'] = kwd_fltr;
      ar['page'] = fltr_wd;
      ar['pagelink'] = pagelink;
      idxarr.push(ar);
    });
    cnt += 1
  }
}

// 再描画用にデータを集める
var replotdata = function(allarr, wd) {

  // wd が直接入力ブックマーク の場合、スラッシュを削除
  if (wd == '直接入力/ブックマーク') {
    wd = wd.replace(/\//g, '');
  }

  var a = [];
  for(i=0; i < allarr[wd].length; i++) {
    allarr[wd][i][3] = String(wd) + ';;' + allarr[wd][i][3];
  }
  a.push( allarr[wd] );
  return a;
}

// グラフ項目と人気ページ項目の絞り込みパラメータを設定
function addNarrowParam(data,  graph, narrow) {

  var option; // 項目名（オプション）
  var a;
  var item = data[1]; // 項目名

  switch (item) {
    case 'PV数':
      graph.val('pageviews');
      break;
    case '平均PV数':
      graph.val('pageviews_per_session');
      break;
    case '訪問回数':
      graph.val('sessions');
      break;
    case '直帰率':
      graph.val('bounce_rate');
      break;
    case '新規訪問率':
      graph.val('percent_new_sessions');
      break;
    case '平均滞在時間':
      graph.val('avg_session_duration');
      break;
    case '再訪問率':
      graph.val('repeat_rate');
      break;
    case '人気ページ':
      narrow.append($('<option>').html(" ").val(data[2] + 'f'));
      narrow.val( data[2] + 'f');
      graph.val('pageviews');
      break;
  }
}

// 項目一覧に表示する流入元データを日本語へ変換(デバイス)
function devTnsltENtoJP (d) {

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
function usrTnsltENtoJP (d) {

  // 変換表
  var options = {
    new: '新規',
    repeat: 'リピーター',
    all: '全訪問者',
  };

  var wd = String(options[d]) === "undefined"? String(options['all']) : String(options[d]);
  return wd;
}

// キーワードがnokwdの場合は半角ブランクへ変換
function kwdTnsltENtoJP (d) {

  var wd;
  if (d === 'nokwd' ) {
    wd = ' ';
  } else {
    wd = d;
  }
  return wd;
}


function getTooltipXaxisToPixels(a, graph) {
  return x = graph.axes.xaxis.u2p(a.attr('data-gap')); // convert x axis unita to pixels
}

function getTooltipYaxisToPixels(a, graph) {
  var soukan = IsZeroSoukan(a.attr('data-sokan'));
  var soukan_percent = chgSoukanToPercent(soukan);
  return y = graph.axes.yaxis.u2p(soukan_percent); // convert y axis unita to pixels
}

function showTooltip(target, x, y) {

  const GRAPH_HEIGHT = 446;
  const GRAPH_WIDTH = 0;

  $(target)
  .tooltipster({
    content: $(
      '<div id="box_r">'
        + '<ul>'
        + '<li>該当データ名</li>'
        + '<li>曜日</li>'
        + '<li>デバイス</li>'
        + '<li>ユーザー</li>'
        + '<li>絞り込み条件</li>'
        + '</ul>'
       + '</div>'
    ),
    position: 'top',
    offsetX: x - GRAPH_WIDTH,
    offsetY: GRAPH_HEIGHT - y,
    speed: 0,
  })
  .tooltipster('show');
}

function hideTooltip(target) {
  $(target)
  .tooltipster('destroy');
}

// バブルチャートの生成(main function)
function plotGraphHome(arr, idxarr) {
  jQuery( function() {

    // バブル（散布図）チャート相関グラフ
    // x軸, y軸, 大きさ(radius), 項目名　の順に表示

    // リプロット用にarr をグローバルオブジェクトとして確保
    arr_for_replot = $.extend(true, {}, arr);

    // グラフ描画対象
    var graph_position = 'gh';

    // グラフ描画オプション
    var options = {
      seriesDefaults: {
        renderer: jQuery.jqplot.BubbleRenderer,
        rendererOptions: {
          // bubbleAlpha: 0.2,
          // highlightAlpha: 1.0,
          showLabels: false,
          autoscaleMultiplier: 0.1,
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
          // label: 'GAP',
          min: 1,
          max: 100,
        },
        yaxis: {
          // label: '相関',
          min: 1,
          max: 100,
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

    // 項目一覧へ要素を追記
    var target = 'div#mfm ul';
    var ed_target = target + ' li:last';
    var click_target = target + ' li a';

    resetHomeRanking(target);
    addRanking(idxarr, target);

    // 項目の最後へタグ付与
    $(ed_target).attr('id', 'ed');

    // 項目一覧へ改行タグ付与
    $(target).append('<br>');

    // 項目一覧データにクリックイベントを追加
    addClickEvtToInfo(click_target);

    // jqplot描画後に実行する操作（jqplot描画前に書くこと）
    $.jqplot.postDrawHooks.push(function(graph) {

      // 目盛り線のみ残して目盛りの値は削除
      var selcts = [ $('.jqplot-xaxis-tick'), $('.jqplot-yaxis-tick') ];
      for (var i=0; i<selcts.length; i++) {
        $(selcts[i][0]).text('');
        $(selcts[i][1]).text('');
        $(selcts[i][2]).text('');
      }
    });

    // jqplot描画
    var graph = jQuery . jqplot(graph_position, arr, options);

    // ブロック項目をホバーしたらプロットへデータ表示
    var tooltip_target = '.tooltip';
    $(click_target).hover(
      function() {
        var x = getTooltipXaxisToPixels($(this), graph);
        var y = getTooltipYaxisToPixels($(this), graph);

        showTooltip(tooltip_target, x, y);
      },
      function() {
        hideTooltip(tooltip_target);
      }
    );

    // ホームグラフをリプロットする
    var replotHome = function(wd, obj) {

      var addopt = { series: [] };

      if (wd == '全データを再表示') {
        addopt.data = obj;
      }

      // 再描画を実行
      // jqplot の replot関数は、追加のオプションを設定すると
      // 追加部分「だけ」変更してくれるので余計な記載をせずに済む。
      graph.replot(addopt);

      // フィルタした処理の内容を記録(グローバル)
      replotHomeflg = wd;
    }
  });
}
