function createGraphPlots(idxarr, arr) {

  var plot_color = {}, tmp_arr = [];

  for (i=0; i < idxarr.length; i++) {

    var x = idxarr[i]['vari'];
    var y = idxarr[i]['corr'];
    plot_color = setBubbleColor(x, y);
    tmp_arr[i] = [ x, y, 1, plot_color];       // グラフx軸, グラフy軸, バブルの大きさ, バブルの色　で指定
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

  $(target).on('click', 'li a', function(e) {

    var target_action = getTargetAction(e);
    var target_action_array = target_action.split('/');

    // グラフ項目を設定
    var metrics = $(e.target).data('metrics');
    addGraphicItem( metrics, $('input[name="graphic_item"]') );
    console.log('graphic_item : ' + $('input[name="graphic_item"]').val());

    // 絞り込みチェックボックスの値を指定
    var dp = $(e.target).data('devfltr');
    var up = $(e.target).data('usrfltr');
    var dayp = $(e.target).data('day-type');
    console.log('dp : ' + dp);
    console.log('up : ' + up);
    console.log('dayp : ' + dayp);

    $.each([dp,up,dayp], function(i, val) {
      var type,n,m;
      type = 'form[name="narrowForm"] input[value=' + val + ']';
      n = $(type).attr("name");
      m = 'form[name="narrowForm"] input[name=' + n + ']';
      $(m).val([val]);
    });

    // 絞り込みキーワードの値を設定
    var kwd = $(e.target).data('kwdfltr');
    console.log('kwd : ' + kwd);

    if (kwd != 'nokwd') {
      var flg; // どのページのキーワードか判別用

      // 遷移先の最後のアクション名を取得
      var action_name = target_action_array[3];

      // 遷移先を判別
      switch (action_name) {
        case 'referral':
          flg = 'r';
          break;
        case 'social':
          flg = 'l';
          break;
      }

      // 遷移先のキーワードとページ情報を設定
      var n_wd = kwd + flg;
      $('#narrow_select')
        .append($('<option>')
          .html(" ")
          .val(n_wd)
        ).val(n_wd);
    }

    // 遷移先の強調項目を設定
    $('input[name="red_item"]').val(metrics);

    // ホーム画面の履歴を保存
    $('input[name="history_from"]').val($('#from').val());
    $('input[name="history_to"]').val($('#to').val());
    $('input[name="history_cv_num"]').val($('input[name="cv_num"]').val());

    // ページ遷移
    evtsend($(e.target));
  });
}

function chkDayType(d) {
  if (typeof d === 'undefined') {
    return '全日';
  } else {
    return d;
  }
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

    var day_type_jp = chkDayType(value['day_type_jp']);

    $(target)
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
            'data-metrics': value['jp_metrics'],
            'data-day-type-jp': day_type_jp,
            'data-day-type': value['day_type'],
            'data-metrics-avg': value['metrics_avg'],
            'data-metrics-stddev': value['metrics_stddev'],
            'data-vari': value['vari'],
            'data-devfltr': value['dev_fltr'],
            'data-usrfltr': value['usr_fltr'],
            'data-kwdfltr': value['kwd_fltr'],
            "name": value['pagelink'],
            'data-category': value['category'],
            'class': 'data-contents'
          })
          .text(counter)
      )
    );
  });

  // 終端処理
  $(target).append($('<br class="clear">'));
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
        console.log('color is red');
    }
    else if ( (x >= XREFERENCE && y <= YREFERENCE) || (x <= XREFERENCE && y >= YREFERENCE) ) {
        label = {color: '#ffc000'};
        console.log('color is yellow');
    }
    else if (x <= XREFERENCE && y <= YREFERENCE) {
        label = {color: '#0070c0'};
        console.log('color is blue');
    }
    return label;
}

function calcCorrPri(data) {
  return data * 2;
}

function calcPriorityData(obj) {
  if (obj.corr >= 0.5 && obj.vari >= 0.5) {
    return 1;
  } else {
    return 0;
  }
}

// データ項目一覧の設定
var setDataidx = function(obj, wd, idxarr) {

  var homearr = $.extend(true, {}, obj), // 参照渡しだとバグる。
    fltr_wd = wd,
    // pagenm = 'div#pnt a.' + fltr_wd,   // ページ名（全体、検索、など）を取得
    // pagelink = $(pagenm).attr('path'),   // ページへのリンクを取得
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
      // ar['pagelink'] = pagelink;
      idxarr.push(ar);
    }
  }
}

// 優先順位の降順、
// 　ページ名と項目名の昇順でソート
// > がマイナスリターン。。降順、< がプラスリターンで昇順
function sortIdxarr(idxarr) {

  var idxarr = idxarr.sort(function(a,b) {
    if (a.pri > b.pri) return  -1;
    if (a.pri < b.pri) return  1;
    if (a.category > b.category) return  1;
    if (a.category < b.category) return  -1;
    if (a.jp_metrics > b.jp_metrics) return  1;
    if (a.jp_metrics < b.jp_metrics) return  -1;
  });
  return idxarr;
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
function addGraphicItem(data, graph) {

  switch (data) {
    case 'PV数':
      graph.val('pageviews');
      break;
    case '平均PV数':
      graph.val('pageviews_per_session');
      break;
    case 'セッション':
      graph.val('sessions');
      break;
    case '直帰率':
      graph.val('bounce_rate');
      break;
    case '新規ユーザー':
      graph.val('percent_new_sessions');
      break;
    case 'ユーザー':
      graph.val('users');
      break;
    case '平均滞在時間':
      graph.val('avg_session_duration');
      break;
    case 'リピーター':
      graph.val('repeat_rate');
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
    wd = d;
  }
  return wd;
}

function getTooltipXaxisToPixels(a, graph) {
  return x = graph.axes.xaxis.u2p(a.attr('data-vari')); // convert x axis unita to pixels
}

function getTooltipYaxisToPixels(a, graph) {
  return y = graph.axes.yaxis.u2p(a.attr('data-corr')); // convert y axis unita to pixels
}

function showTooltip(contents) {

  var position = (function() {
    if (contents.data['vari'] >= 0.5) {
      return 'hvr_r';
    } else {
      return 'hvr_l';
    }
  }());

  $('#graph')
  .prepend(
    $("<div>")
    .attr("id", "fm_graph")
    .append(
      $("<div>")
      .attr("id", position)
      .append(
        $("<dl>")
        .attr("id", "tgt")
        .append(
          $('<dt>')
          .text( contents.data('metrics') )
        )
        .append(
          $('<dd>')
          .text("1,234")
          .append(
            $('<span>')
            .attr("id", "gp")
            .text('(+123)')
          )
        )
      )
      .append(
        $('<ul>')
        .attr("id", "bottom")
        .append($("<li>").append(
          $("<dl>")
            .append($("<dt>").text("流入元"))
            .append($("<dd>").text( $( document.getElementById(contents.data('category')) ).text() ))
          )
        )
        .append($("<li>").append(
          $("<dl>")
            .append($("<dt>").text("曜日"))
            .append($("<dd>").text( contents.data('day-type-jp') ))
          )
        )
        .append($("<li>").append(
          $("<dl>")
            .append($("<dt>").text("デバイス"))
            .append($("<dd>").text( devTnsltENtoJP(contents.data('devfltr')) ))
          )
        )
        .append($("<li>").append(
          $("<dl>")
            .append($("<dt>").text("ユーザー"))
            .append($("<dd>").text( usrTnsltENtoJP(contents.data('usrfltr')) ))
          )
        )
        .append($("<li>").append(
          $("<dl>")
            .append($("<dt>").text("その他条件"))
            .append($("<dd>").text( kwdTnsltENtoJP(contents.data('kwdfltr')) ))
          )
        )
      )
    )
  );
}

function removeKeywordForPageName() {
  switch (getAnalyzedPageName()) {
    case 'all':
    case 'search':
    case 'direct':
      $(".tooltipster-content #box_r ul li#keyword").remove();
    break;
  }
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
    var graph_position = 'graph';

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

    // 項目一覧へ要素を追記
    var rank_target = '#rank';

    addRanking(idxarr, rank_target);
    // 項目一覧データにクリックイベントを追加
    // addClickEvtToInfo(rank_target);

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

    var graph = jQuery . jqplot(graph_position, arr, options);

    // ブロック項目をホバーしたらプロットへデータ表示
    $(rank_target).on({
        'mouseenter': function() {
          console.log('hover mouse');
          replotHome($(this));
          showTooltip($(this));
        },
        'mouseleave': function() {
          console.log('leave mouse');
          replot_options = {
            seriesDefaults: {
              rendererOptions: {
                autoscaleMultiplier: 0.1,
              },
            },
            series: []
          };
          replot_options.data = arr_for_replot;
          graph.replot(replot_options);
        }
      }, 'a');

    // ホームグラフをリプロットする
    var replotHome = function(target) {

      var origin_arr = $.extend(true, {}, arr_for_replot), // 参照渡しだとバグる。
        p_color = setBubbleColor(target.data('vari'), target.data('corr')),
        addopt = [target.data('vari'), target.data('corr'), 1, p_color];
      var add_options = {
        seriesDefaults: {
          rendererOptions: {
            autoscaleMultiplier: 0.4,
          },
        },
        series: [],
      };

      origin_arr[0] = [addopt];
      add_options.data = origin_arr;

      // 再描画を実行
      // jqplot の replot関数は、追加のオプションを設定すると
      // 追加部分「だけ」変更してくれるので余計な記載をせずに済む。
      graph.replot(add_options);
    }
  });
}
