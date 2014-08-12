// データ項目一覧の設定
var setDataidx = function() {

  var homearr = $.extend(true, {}, gon.homearr); // 参照渡しだとバグる。
  var idxarr = [];
  var arr = [];
  var cnt = 0;

  for (var i in homearr) {
    arr.push( homearr[i] );
    arr[cnt].forEach( function(value) {
      var nm = value[3].split(';;');
      value[3] = String(i) + ';;' + value[3];
      var ar = new Array();

      // GAPと相関の合計値が高いものほど優先度を高くする。
      var pri = value[0] + value[1];
      ar['pri'] = pri;
      ar['arr'] = value;
      ar['page'] = String(i);
      ar['name'] = nm[0];
      idxarr.push(ar);
    });
    cnt += 1
  }
  return idxarr;
}

// グラフデータ全設定
var setData = function(opt) {

  var homearr = $.extend(true, {}, gon.homearr); // 参照渡しだとバグる。
  var arr = [];
  var cnt = 0;

  for (var i in homearr) {
    arr.push( homearr[i] );
    arr[cnt].forEach( function(value) {
      value[3] = String(i) + ';;' + value[3];
    });

    // グラフ描画オプション追加
    setGraphcolor( i, opt );
    cnt += 1
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

// グラフ項目の色を決定
function setGraphcolor(wd, opt) {

  // wd が直接入力ブックマーク の場合、スラッシュを削除
  if (wd == '直接入力/ブックマーク') {
    wd = wd.replace(/\//g, '');
  }

  var p_wd = wd

  switch (p_wd) {

    case '全体':
      opt.series.push( { color: '#808080'} );
      break;
    case '検索':
      opt.series.push( { color: '#e6b422'} );
      break;
    case '直接入力ブックマーク':
      opt.series.push( { color: '#008000'} );
      break;
    case 'その他ウェブサイト':
      opt.series.push( { color: '#1e50a2'} );
      break;
    case 'ソーシャル':
      opt.series.push( { color: '#c9171e'} );
      break;
    case 'キャンペーン':
      opt.series.push( { color: '#800080'} );
      break;
  }
}

// グラフ項目のinputパラメータを設定
function setItem(data,  graph, narrow) {
  var option; // 項目名（オプション）
  var tips = ''; // ツールチップの テキスト
  var supl = ''; // 項目一覧のテキスト

  var tab = data[0]; // 各ページ名
  var a;
  var item = data[1]; // 項目名
  tips = tab + ':' + item;
  switch (item) {
    case 'PV数':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('pageviews');
      break;
    case '平均PV数':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('pageviews_per_session');
      break;
    case '訪問回数':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('sessions');
      break;
    case '直帰率':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('bounce_rate');
      break;
    case '新規訪問率':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('percent_new_sessions');
      break;
    case '平均滞在時間':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('avg_session_duration');
      break;
    case '再訪問率':
      tips = tips + '<br>' + chk_days(data);
      supl = chk_days(data);
      graph.val('repeat_rate');
      break;
    case '人気ページ':
      tips = tips + '<br>' + data[2];
      supl = data[2] + '<p>' + data[3] + '</p>'
      $('#narrow_select').val( data[2] + 'f');
      break;
  }
  return [ tips, supl ];
}

// 曜日別の判定
function chk_days(data) {
  var d;
  if (data.length == 3) {
    d = data[2];
    // tips = tips + '<br>' + data[2];
  }else{
    d = ' ';
  }
  return d;
}

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
        label: 'GAP',
        min: -1,
        max: 101,
      },
      yaxis: {
        label: '相関',
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

  // グラフデータを設定
  if (typeof(gon.homearr) == "undefined") {

    // コントローラからデータが渡されない場合
    var arr = [
      [ 1, 1, 1, 'tst' ]
    ];

  } else {

    // データセット
    var arr = setData(options);

   // データ項目一覧セット
    var idxarr = setDataidx();

    // 優先順位の降順、ページ名、項目名の昇順でソート
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
    idxarr.forEach(function(value){

      counter = counter + 1;

      // ページ名（全体、検索、など）を取得
      text = value['arr'][3].split(';;');
      pagenm = 'li.tab > a:contains(' + String(text[0]) + ')';

      // ページへのリンク
      pagelink = $(pagenm)[0].name;

      // 補足情報
      // var tips = setItem( text, $('input[name="graphic_item"]'), $('#narrow_select') );

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
              'data-page': value['arr'][3] })
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
        // console.log(item);

        // グラフ項目と人気ページパラメータを設定
        setItem( item, $('input[name="graphic_item"]'), $('#narrow_select') );

        // ページ遷移
        evtsend($(e.target).closest('td'));
    });

  }

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
  var graph = jQuery . jqplot('graph', arr, options);

  // ハイライトツールチップを表示
  $('#graph').bind('jqplotDataHighlight',
    function (ev, seriesIndex, pointIndex, data, radius) {
      var
        dt = data[3].split(';;'),
        color = 'black',
        chart_left = $('#graph').offset().left,
        chart_top = $('#graph').offset().top,
        // convert x axis unita to pixels
        x = graph.axes.xaxis.u2p(data[0]),
        // convert y axis units to pixels
        y = graph.axes.yaxis.u2p(data[1]);
      // console.log( "full data is " + dt );

      var page = 'li.tab > a:contains(' + String(dt[0]) + ')';
      var id = $(page)[0].name;
      console.log( "href action is " + id );

      var tips = setItem( dt, $('input[name="graphic_item"]'), $('#narrow_select') );
      // console.log( "tooptip is  " + tips );
      // ツールチップのCSS
      $('#tooltip1s').css(
        {
          left: chart_left+x+radius + -5,
          top: chart_top+y,
          'text-align': 'center'
        });
      // ツールチップHTML
      $('#tooltip1s').html(
          '<a href="javascript:void(0)" name=' + id +' class="abtn" '
          + ' style="font-size:14px;' +
          'font-weight:bold;color:' + color + ';background-color: whitesmoke;">'
          + tips[0]
          + '</a>'
        );
      $('#tooltip1s').show();
      // ツールチップへリンク付与
      $("a.abtn").click(function(){
        evtsend($(this));
      });

    }
  );

  // ハイライトツールチップを隠す
  $('#graph').bind('jqplotDataUnhighlight',
      function (ev, seriesIndex, pointIndex, data) {
          // 絞り込み選択を解除
          $('#narrow_select').each(function() {
            this.selectedIndex = 0;
          });
          // グラフ描画オプションをpageview(初期値)に戻す
          $('input[name="graphic_item"]').val('pageviews');
          $('#tooltip1s').empty();
          $('#tooltip1s').hide();
      }
  );

  // 項目一覧データをマウスオーバしたら該当データのみリプロットする
  $('#legend1b tr td.r a').hover(
    function() {
      var $parents = $(this).parent('td.r');
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
      setGraphcolor(text[0], addopt);
      // console.log("replot strong " + text[0] );
      graph.replot(addopt);
    },
    function() {
      // 最後にフィルタしたグラフへ戻す
      if (typeof(replotHomeflg) == "undefined") {
        replotHomeflg = '全データを再表示';
      }
      replotHome(replotHomeflg);
    }
  );

  // 再描画ボタンがクリックされたらグラフをリプロットする
  $('#circle .replot').click(function() {
    var wd = $(this).text();
    replotHome(wd);
  })

  // ホームグラフをリプロットする
  var replotHome = function(wd) {

    var addopt = { series: [] };

    if (typeof(gon.homearr) != "undefined" ) {

      if (wd == '全データを再表示') {
        var arr = setData(addopt);
        addopt.data = arr;
      } else {
        var src = $.extend(true, {}, gon.homearr); // 参照渡しだとバグる。
        var rdata = replotdata(src, wd);
        addopt.data = rdata;
        setGraphcolor(wd, addopt);
      }
      console.log("replot " + wd);
      // 再描画を実行
      // jqplot の replot関数は、追加のオプションを設定すると
      // 追加部分「だけ」変更してくれるので余計な記載をせずに済む。
      graph.replot(addopt);

      // フィルタした処理の内容を記録(グローバル)
      replotHomeflg = wd;

    } else {
      console.log('描画対象のデータがないため、再描画は実行されません');
    }
  }
});
