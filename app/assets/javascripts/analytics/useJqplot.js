var arr = [];

var setArr = function(hash) {
    var arr_gap = [], arr_cv = [], dts;
    for (var i in hash) {
      dts = i.toString();
      dts = String(Number(dts.substr(4, 2)))
        + "/" + String(Number(dts.substr(6, 2)));
      arr_gap.push( [ dts, gon.hash_for_graph[i][0] ]);
      arr_cv.push( [ dts, gon.hash_for_graph[i][1] ]);
    };
    arr.push(arr_gap, arr_cv);
}

var tickFormatter = function (format, val) {
    switch(format) {
        case 'percent': return val.toFixed(1) + '%';
        case 'number': return val.toFixed(1);
        case 'time': {

            /*
            時間の書式は、 hh:mm:ss
            */
            val_org = val;
            val = Math.abs(parseInt(val));
            var h=""+(val/36000|0)+(val/3600%10|0);
            var m=""+(val%3600/600|0)+(val%3600/60%10|0);
            var s=""+(val%60/10|0)+(val%60%10);
            var s = h +':' + m + ':' + s;
            // console.log('converted time is ' + s);
            if(val_org - 0 < 0) {
                s = "-" + s;
            }
            return s;
        }
        default: return val;
    }
}

// hh:mm:ss 時間のフォーマットを秒数へ
var timeTonum = function(val) {

  var hms = val.split(':');
  var sec = parseInt(hms[2]) + parseInt(hms[1]) * 60 + parseInt(hms[0]) * 3600;
  if (hms[0].substr(0,1) == '-') {
    sec = -sec;
  }
  return sec;
}

// y軸の目盛りを数値へ関数
var setYgridnum = function(format, val) {
  switch(format) {
      case 'percent':
      case 'number':
        return parseFloat(val);
      case 'time': {
        val = timeTonum(val);
        return val;
      }
      default: return val;
    }
}

// Y軸の目盛りを再設定
var resetYtick = function(val) {

  var line, tick, data = {};

  tick = val;
  if (val == 0) {
    line = 'horizontalLine';
  } else {
    line = 'dashedHorizontalLine';
  }

  data[line] = {
    y: tick,
    shadow: false,
    shadowAlpha: 0,
    shadowAngle: 0,
    color: 'gray',
    dashPattern: [4,4],
    lineCap: 'square',
    lineWidth: 0.8
  };

  return data;
}

// x軸（日付）の値に合わせてグラフ背景色を変更
var resetXbgc = function(nm, dt) {

  var data = {}, bgc, d = dt + 1;

  if ( (nm == 'day_sun') || (nm == 'day_hol') )  {
    bgc = "#FFEEFF";
  } else if (nm == 'day_sat') {
    bgc = "#EEFFFF";
  }

  data['line'] = {
    start : [d - 0.5, 100],
    stop : [d + 0.5, 100],
    lineWidth: 1000,
    color: bgc,
    shadow: false,
    lineCap : 'butt'
  };
  return data;
}

// 実験コード：　マイナスデータを表示させたい場合
// gon.hash_for_graph[20121205][0] = -12;
// gon.hash_for_graph[20121205][1] = -10;
// gon.hash_for_graph[20121210][0] = -70;
// gon.hash_for_graph[20121210][1] = 40;


setArr(gon.hash_for_graph);

// グラフのオプション
var options = {
    seriesColors: ["#e6b422", "#1e50a2"],
    seriesDefaults: {
      shadow: false,
    },
    axesDefaults: {
        tickOptions: {
          fontSize: '9.5pt',
          fontFamily: 'ヒラギノ角ゴ Pro W3'
        },
    },
    series:[
          // １つ目の項目（棒グラフにする）の設定
        {
            renderer: jQuery . jqplot . BarRenderer,
            fillToZero: true,
            negativeSeriesColors: ["#e6b422"],
            rendererOptions: {
            },
        },
          // ２つ目の項目（折れ線グラフにする）の設定
        {
            xaxis: 'x2axis',
            yaxis: 'y2axis',
        }
    ],
    axes: {
        xaxis: {
            renderer: jQuery . jqplot . CategoryAxisRenderer,
            tickOptions: {
              fontSize: '9pt',
              showGridline: false,
              // 項目の延長線は削除（なんかヒゲみたいで嫌）
              markSize: 0
            },
        },
        x2axis: {
            renderer: jQuery . jqplot . CategoryAxisRenderer,
            tickOptions: {
              showGridline: false,
              markSize: 0
            },
            borderWidth: 0,
        },
        yaxis: {
            autoscale: true,
            numberTicks: 10,
            pad: 1,
            tickOptions: {
              // GAP値は自作関数でフォーマットする
              formatter: tickFormatter,
              showGridline: false,
            },
        },
        y2axis: {
            autoscale: true,
            numberTicks: 10,
            pad: 1,
            tickOptions: {
              showGridline: false,
            },
        },
    },
    // マウスオーバー時の数値表示
    highlighter: {
        // show: true,
        formatString: '<table class="jqplot-highlighter"><tr><td>%s</td><td>日</td></tr><tr><td> </td><td>%s</td></tr></table>'
    },
    // 背景色に関する設定
    grid: {
      background: "transparent",
      gridLineColor: "gray",
      shadow: false,
      drawBorder: true,
    },
};

// グラフのフォーマット設定は自作関数で行う
options.axes.yaxis.tickOptions.formatString = gon.format_string;

jQuery( function() {

  // 再描画用のオプション
  tickopt = {
    canvasOverlay: {
      show: true,
      objects: []
    }
  };

  // jqplot描画後に実行する操作（jqplot描画前に書くこと）
  $.jqplot.postDrawHooks.push(function() {
      $('.jqplot-axis.jqplot-x2axis').hide();

      // x軸（日付）の処理
      for ( var i=0; i < $('.jqplot-xaxis-tick').length; i++) {

        var text = $( $('.jqplot-xaxis-tick')[i] ).text();
        var date = 'td[data-dflg]:contains(' + String(text) + ')';
        var name = $(date).attr("data-dflg");
        var dt;
        // console.log(name);

        // 土曜日の部分背景を青、日祝なら赤に変更
        if (name != 'day_on') {
          dt = resetXbgc(name, i);
          tickopt.canvasOverlay.objects.push(dt);
        }

        // 土曜日なら文字列を青、日祝なら文字列を赤に変更
        if (name == 'day_sun' || name == 'day_hol') {
          $( $('.jqplot-xaxis-tick')[i] ).css("color", "red");
        } else if (name == 'day_sat') {
          $( $('.jqplot-xaxis-tick')[i] ).css("color", "blue");
        }

        // 32日以上データがあるなら平日は非表示にする
        if ( $('.jqplot-xaxis-tick').length >= 32 ) {
          if (name == 'day_on') {
            $( $('.jqplot-xaxis-tick')[i] ).text('');
          }
        }

      }

      // グラフの下部マージンを変更
      $('#square.jqplot-target').css("margin-bottom", "20px");

      // y軸の罫線を後ろに移動
      $('.jqplot-overlayCanvas-canvas').css("z-index", -1);

  });

  // jqplot描画
  squareBar = jQuery . jqplot( 'square', arr, options);

  // グラフのy座標へ水平線を設定
  var yticks = $('.jqplot-yaxis-tick');
  var tick;
  var dt;

  for(var i=0; i < yticks.length; i++) {

    // 目盛りの値を変換
    tick = setYgridnum(gon.format_string, $(yticks[i]).text());
    // console.log(tick);

    // y軸を再設定
    dt = resetYtick(tick)
    tickopt.canvasOverlay.objects.push(dt);
 }
 // jqplot再描画
 squareBar.replot(tickopt);

} );
