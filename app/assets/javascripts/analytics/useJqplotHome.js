// データ項目一覧の設定
var setDataidx = function(obj, wd) {

  var homearr = $.extend(true, {}, obj); // 参照渡しだとバグる。
  var idxarr = [];
  var arr = [];
  var cnt = 0;
  var fltr_wd = wd;

  for (var i in homearr[fltr_wd]) {
    arr.push( homearr[fltr_wd][i] );
    arr[cnt].forEach( function(value) {
      var nm = value[3].split(';;');
      value[3] = fltr_wd + ';;' + value[3];

      // GAPと相関の合計値が高いものほど優先度を高くする。
      var ar = new Array();
      var pri = value[0] + value[1];
      ar['pri'] = pri;
      ar['arr'] = value;
      ar['name'] = nm[0];
      ar['param'] = String(i);
      ar['page'] = fltr_wd;
      idxarr.push(ar);
    });
    cnt += 1
  }
  return idxarr;
}

// グラフデータ全設定
var setData = function(opt, obj, wd) {

  var homearr = $.extend(true, {}, obj); // 参照渡しだとバグる。
  var arr = [];
  var cnt = 0;
  var fltr_wd = wd;

  for (var i in homearr[fltr_wd]) {
    arr.push( homearr[fltr_wd][i] );
    arr[cnt].forEach( function(value) {
      value[3] = String(i) + ';;' + value[3];
    });

    // グラフ描画オプション（プロットデータのカラー）追加
    // setGraphcolor( i, opt );

    cnt += 1;
  }
  return arr;
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


// バブルチャートの生成
function plotGraphHome(robj, fltr) {
  jQuery( function() {

    // バブル（散布図）チャート相関グラフ
    // x軸, y軸, 大きさ(radius), 項目名　の順に表示
    // x ... GAP y ... 相関　で現す。

    // グラフ描画オプション
    var options = {
      seriesDefaults: {
        renderer: jQuery.jqplot.BubbleRenderer,
        rendererOptions: {
          bubbleAlpha: 0.2,
          highlightAlpha: 1.0,
          showLabels: false,
          varyBubbleColors: false,
          autoscaleMultiplier: 0.15,
          shadow: false,
        },
      },
      series: [], // ここに関数でカラーセットを行う
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
      }
    };

    // ホーム画面で指定したページ項目名
    var page_fltr_wd = fltr;

    // データセット
    var arr = setData(options, robj, page_fltr_wd);

    // データ項目一覧セット
    var idxarr = setDataidx(robj, page_fltr_wd);

    // 優先順位の降順、
    // 　ページ名と項目名の昇順でソート
    // > がマイナスリターン。。降順、< がプラスリターンで昇順
    idxarr = idxarr.sort(function(a,b) {
      if (a.pri > b.pri) return  -1;
      if (a.pri < b.pri) return  1;
      if (a.page > b.page) return  1;
      if (a.page < b.page) return  -1;
      if (a.name > b.name) return  1;
      if (a.name < b.name) return  -1;
    });

    // 項目一覧へ表示する項目番号
    var counter = 0;
    // 項目一覧へ表示する文字列
    var caption;
    var ptxt, pagenm, pagelink;

    // 項目一覧データを追記
    idxarr.some(function(value){

      // 表示件数の上限を50件に制限
      if (counter >= 50) {
        return false;
      }

      counter = counter + 1;

      // ページ名（全体、検索、など）を取得
      pagenm = 'li.tab > a:contains(' + page_fltr_wd + ')';

      // ページへのリンクを取得
      pagelink = $(pagenm)[0].name;

      // 絞り込み情報の追加
      text = value['arr'][3].split(';;');
      addNarrowParam( text, $('input[name="graphic_item"]'), $('#narrow_select') );

      // 項目一覧へ表示する文字列
      caption = text[0] + ':' + text[1];

      $('#legend1b').append(
        $('<tr>').append(
          $('<td>')
            .attr("class", "l")
            .text(counter)
          ).append(
            $('<td>')
            .attr({
              "name": pagelink,
              "class": "r",
              'data-gap': value['arr'][0],
              'data-sokan': value['arr'][1],
              'data-page': value['arr'][3],
              'data-param': value['param']
            })
            .append(
              $('<a>')
                .attr({
                  "href": 'javascript:void(0)'})
                .text(caption)
              )
        )
      );
    });

    // 項目一覧データにクリックイベントを追加
    $('#legend1b tr td a').click(function(e) {

        //要素の先祖要素で一番近いtdの
        //data-page属性の値を加工する
        var item = $(e.target).closest('td').data('page').split(';;');
        console.log(item);

        // グラフ項目と人気ページパラメータを設定
        addNarrowParam( item, $('input[name="graphic_item"]'), $('#narrow_select') );

        // 絞り込みチェックボックスパラメータを指定
        var param = $(e.target).closest('td').data('param');
        switch (param) {
          case 'all':
            $("#hallway input[name='device']").val(['all']);
            $("#hallway input[name='visitor']").val(['all']);
            break;
          default :
            var type = '#hallway input[value=' + param + ']';
            var n = $(type).attr("name");
            var m = '#hallway input[name=' + n + ']';
            $(m).val([param]);
            break;
        }


        // ページ遷移
        evtsend($(e.target).closest('td'));
    });

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

        // 絞り込み項目のセット
        // $('input[name="device"]')

        var text = $parents.attr('data-page').split(';;');
        // [ gap, 相関, radius(バブルの大きさ), テキスト ] の配列を生成
        var rearr = [
          [
            [parseInt($parents.attr('data-gap')), parseInt($parents.attr('data-sokan')), 5, $parents.attr('data-page') ]
          ]
        ];
        // console.log(rearr);
        var addopt = { series: [] };
        addopt.data = rearr;
        // setGraphcolor(text[0], addopt);
        // console.log("replot strong " + text[0] );
        graph.replot(addopt);
      },
      function() {
        // 最後にフィルタしたグラフへ戻す
        if (typeof(replotHomeflg) == "undefined") {
          replotHomeflg = '全データを再表示';
        }
        replotHome(replotHomeflg, robj);
      }
    );

    // ホームグラフをリプロットする
    var replotHome = function(wd, obj) {

      var addopt = { series: [] };

      if (wd == '全データを再表示') {
        var arr = setData(addopt, obj, page_fltr_wd);
        addopt.data = arr;
      } else {
        var src = $.extend(true, {}, obj); // 参照渡しだとバグる。
        var rdata = replotdata(src, wd);
        addopt.data = rdata;
        // setGraphcolor(wd, addopt);
      }
      console.log("replot " + wd);
      // 再描画を実行
      // jqplot の replot関数は、追加のオプションを設定すると
      // 追加部分「だけ」変更してくれるので余計な記載をせずに済む。
      graph.replot(addopt);

      // フィルタした処理の内容を記録(グローバル)
      replotHomeflg = wd;
    }
  });
}
