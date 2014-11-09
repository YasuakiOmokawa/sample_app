function createPlotArr(idxarr, arr) {

  var plot_color = {}, tmp_arr = [];

  for (i=0; i < idxarr.length; i++) {

    plot_color = setBubbleColor(idxarr[i]['arr'][0], idxarr[i]['arr'][1]);

    // x, y, radius, plot_color
    tmp_arr[i] = [idxarr[i]['arr'][0], idxarr[i]['arr'][1], 1, plot_color];
  }

  arr.push(tmp_arr);
}

function headIdxarr(idxarr, limit) {

  var headed_obj = [];

  if (idxarr.length < limit) {
    return idxarr;
  }

  for (var i=0; i < idxarr.length; i++) {

    headed_obj[i] = idxarr[i];

    // 表示件数の上限を30件に制限
    if (i >= limit -1) {
      return headed_obj;
    }
  }

}

// 項目一覧データにクリックイベントを追加
function addClickEvtToInfo() {

  $('#legend1b tr td a').click(function(e) {

      //要素の先祖要素で一番近いtdの
      //data-page属性の値を加工する
      var item = $(e.target).closest('td').data('page').split(';;');
      console.log(item);

      // グラフ項目と人気ページパラメータを設定
      addNarrowParam( item, $('input[name="graphic_item"]'), $('#narrow_select') );

      // 絞り込みチェックボックスの値を指定
      var dp = $(e.target).closest('td').data('devfltr');
      var up = $(e.target).closest('td').data('usrfltr');

      $.each([dp,up], function(i, val) {
        var type,n,m;
        type = '#hallway input[value=' + val + ']';
        n = $(type).attr("name");
        m = '#hallway input[name=' + n + ']';
        $(m).val([val]);
      });

      // 絞り込みキーワードの値を設定
      var kp = $(e.target).closest('td').data('kwdfltr'); // キーワード

      if (kp != 'nokwd') {
        var flg; // どのページのキーワードか判別用

        // 遷移先の最後のアクション名を取得
        var p = $(e.target).closest('td').attr("name");
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
          case 'campaign':
            flg = 'c';
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
      $('input[name="red_item"]').val(item[1]);

      // 遷移先ページタブ情報を保持
      var prev_page = String(item[0]);
      $('input[name="prev_page"]').val(prev_page);

      // ページ遷移
      evtsend($(e.target).closest('td'));
  });
}

// 項目一覧へ要素を追記
function addInfo(idxarr) {

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
    // addNarrowParam( text, $('input[name="graphic_item"]'), $('#narrow_select') );

    // 項目一覧へ表示する文字列
    // ページ項目:データ指標：デバイス：ユーザー：絞り込み条件(あれば)
    caption = text[0] + ':' + text[1] + ':' + devTnsltENtoJP(value['dev_fltr']) + ':' + usrTnsltENtoJP(value['usr_fltr']) + ':' + kwdTnsltENtoJP(value['kwd_fltr']);

    $('#legend1b').append(
      $('<tr>').append(
        $('<td>')
          .attr("class", "l")
          .text(counter)
        ).append(
          $('<td>')
          .attr({
            "name": value['pagelink'],
            "class": "r",
            'data-gap': value['arr'][0],
            'data-sokan': value['arr'][1],
            'data-page': value['arr'][3],
            'data-devfltr': value['dev_fltr'],
            'data-usrfltr': value['usr_fltr'],
            'data-kwdfltr': value['kwd_fltr']
          })
          .append(
            $('<a>')
              .attr({
                "href": 'javascript:void(0)',
                "title": caption,
              })
              .text(caption)
            )
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
  var pagenm = 'li.tab > a:contains(' + fltr_wd + ')';   // ページ名（全体、検索、など）を取得
  var pagelink = $(pagenm)[0].name;   // ページへのリンクを取得

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

// バブルチャートの生成(main function)
function plotGraphHome(arr, idxarr) {
  jQuery( function() {

    // バブル（散布図）チャート相関グラフ
    // x軸, y軸, 大きさ(radius), 項目名　の順に表示
    // x ... GAP y ... 相関　で現す。

    // リプロット用にarr をグローバルオブジェクトとして確保
    arr_for_replot = $.extend(true, {}, arr);

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
          min: -1,
          max: 101,
        },
        yaxis: {
          // label: '相関',
          min: -1,
          max: 101,
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
    addInfo(idxarr);

    // 項目一覧データにクリックイベントを追加
    addClickEvtToInfo();

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
    var graph = jQuery . jqplot('gp', arr, options);

    // 項目一覧データをマウスオーバしたら該当データのみリプロットする。
    // 同時に、絞り込み項目も自動でセットさせる
    $('#legend1b tr td.r a').hover(
      function() {

        var $parents = $(this).parent('td.r');

        var text = $parents.attr('data-page').split(';;');
        // [ gap, 相関, radius(バブルの大きさ), テキスト ] の配列を生成
        var b = setBubbleColor($parents.attr('data-gap'), $parents.attr('data-sokan'));
        var rearr = [
          [
            [parseInt($parents.attr('data-gap')), parseInt($parents.attr('data-sokan')), 1, b]
          ]
        ];
        // console.log(rearr);
        var addopt = { series: [] };
        addopt.data = rearr;
        graph.replot(addopt);
      },
      function() {
        // 最後にフィルタしたグラフへ戻す
        if (typeof(replotHomeflg) == "undefined") {
          replotHomeflg = '全データを再表示';
        }
        replotHome(replotHomeflg, arr_for_replot);
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
