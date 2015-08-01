function zeroSuppressedDateFormat(data) {
  date = Number(data.substr(4, 2)).toString() + "/" + Number(data.substr(6, 2)).toString();
  return date;
}

function zeroSuppressedDateFormatMonthly(data) {
  date = Number(data.substr(0, 4)).toString() + "/" + Number(data.substr(4, 2)).toString();
  return date;
}

// コントローラから渡されたパラメータをグラフ描画用の配列に加工
var setArr = function(data) {
    var arr_metrics = [], dts, arr = [];
    for (var i in data) {

      if (i.toString().length == 8) {
        dts = zeroSuppressedDateFormat(i.toString());
      } else {
        dts = zeroSuppressedDateFormatMonthly(i.toString());
      }

      arr_metrics.push( [ dts, data[i].data, data[i].day_type ] );
    };
    arr.push(arr_metrics);
    return arr;
}

// 表示する値の種類によって、グラフのY軸（左側）のフォーマットを変更
var tickFormatter = function (format, val) {
    switch(format) {
        case 'percent': return RoundValueUnderOne(val) + '%';
        case 'number': return String( parseInt(val, 10) ).replace( /(\d)(?=(\d\d\d)+(?!\d))/g, '$1,');
        case 'time': {

            // 時間の書式は、 hh:mm:ss
            val_org = val;
            val = Math.abs(parseInt(val));
            var h =""+(val/36000|0)+(val/3600%10|0);
            var m =""+(val%3600/600|0)+(val%3600/60%10|0);
            var s =""+(val%60/10|0)+(val%60%10);
            // s = h +':' + m + ':' + s; // 20140901 mm:ss 形式へ変更（分は3桁以上を許容）
            m = parseInt(m) + parseInt(h) * 60;
            m = "" + m;
            if (m.length < 2) {
              m = "0" + m;
            }
            s = m + ':' + s;
            // console.log('converted time is ' + s);

            if(val_org - 0 < 0) {
                s = "-" + s;
            }
            return s;
        }
        default:
          return val;
    }
}

// Y軸の目盛りを再設定
var resetYtick = function(val) {

  var color, tick, data = {};

  tick = val;
  if (val == 0) {
    color = '#000000';
  } else {
    color = '#a9a9a9';
  }

  data['horizontalLine'] = {
    xaxis: 'xaxis',
    yaxis: 'yaxis',
    y: tick,
    shadow: false,
    shadowAlpha: 0,
    shadowAngle: 0,
    color: color,
    lineCap: 'square',
    lineWidth: 0.5,
  };

  return data;
}

// x軸（日付）の値に合わせてグラフ背景色を変更
var resetXbgc = function(nm, dt, yval) {

  var data = {}, bgc, d = dt + 1;

  if ( (nm == 'day_sun') || (nm == 'day_hol') )  {
    bgc = "#fa8072";
  } else if (nm == 'day_sat') {
    bgc = "#b0c4de";
  }

  data['line'] = {
    xaxis: 'xaxis',
    yaxis: 'yaxis',
    start : [d - 0.5, yval],
    stop : [d + 0.5, yval],
    lineWidth: 100000,
    color: bgc,
    shadow: false,
    lineCap : 'butt',
  };
  return data;
}

function setYaxisLimit(options, format) {
  if (format === 'percent') {
    options.axes.yaxis.min = 0;
    options.axes.yaxis.max = 100;
  }
  return options;
}

// ツールチップの表示形式
var getPointInfo = function(current, serie, index, plot) {
  var item = JSON.parse(sessionStorage.getItem('data_for_detail'));
  var kv = plot.data[serie][index];
  var format = '<div>'
                        + kv[0]
                      + '</div>'
                      +'<div>'
                        // + item.metricsJp + ': ' + tickFormatter(item.metricsFormat, kv[1])
                        + tickFormatter(item.metricsFormat, kv[1])
                      + '</div>';

  return format;
}

var calcYMax = function(graph_data) {
  return Math.max.apply(null, graph_data[0].map(function(v) {
      return Number(v[1]);
    } )
  );
}

// メイン処理
function jqplotDetail(format) {

  var graph_data = setArr(gon.data_for_graph_display);

  // グラフのオプション
  var options = {
      seriesColors: ["#5383c3"],
      seriesDefaults: {
        shadow: false,
        markerOptions: {
          show: true,
          shadow: false,
        },
      },
      axesDefaults: {
          tickOptions: {
            fontSize: '9pt',
            fontFamily: 'ヒラギノ角ゴ Pro W3',
          },
      },
      // グラフ幅の調整
      gridPadding: { top: 0, bottom: 0, left: 0, right: 0 },
      series:[
            // １つ目の項目の設定
          {
            rendererOptions: {
              lineWidth: 1,
            },
          },
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
          yaxis: {
              numberTicks: 3,
              min: 0.0,
              tickOptions: {
                showGridline: false,
                markSize: 0,
              },
          },
      },
      // マウスオーバー時の数値表示
      highlighter: {
          show: true,
          fadeToolTip: false,
          tooltipContentEditor: getPointInfo,
          // tooltipLocation: 'e',
      },
      // 背景色に関する設定
      grid: {
        background: "transparent",
        gridLineColor: "transparent",
        shadow: false,
        drawBorder: false,
        drawGridlines: false,
      },
  };

  // yの最大値をデータより算出
  options.axes.yaxis.max = calcYMax(graph_data);

  // 再描画用のオプション
  var tickopt = {
    canvasOverlay: {
      show: true,
      objects: [],
      yaxis: {},
    }
  };

  // jqplot描画後に実行する操作（jqplot描画前に書くこと）
  resetPostDrawHooks();
  var detailPostDraw = function detailPostDraw() {
    var ymax_value = calcYMax(this.data),
      $xticks = $('.jqplot-xaxis-tick'), xlength = graph_data[0].length - 1;

    for ( var i=0; i < graph_data[0].length; i++) {

      var day_type = this.data[0][i][2];
      var background_graph_color;

      // 土日祝日の部分背景を変更
      if (day_type != 'day_on') {
        background_graph_color = resetXbgc(day_type, i, ymax_value);
        tickopt.canvasOverlay.objects.push(background_graph_color);
      }

      // 日付表示数の最適化
      if (day_type != 'day_sun') {
        $( $xticks[i] ).text('');
      }
    }

    var item = JSON.parse(sessionStorage.getItem('data_for_detail'));
    var $yticks = $('.jqplot-yaxis-tick');

    for(var i=0; i < $yticks.length; i++) {

      // 目盛りの値を変換
      var tick, dt;
      tick = $( $yticks[i] ).text();

      // グラフのy座標へ水平線を設定
      // y軸を再設定
      dt = resetYtick(tick);
      tickopt.canvasOverlay.objects.push(dt);

      // Y軸の目盛りの値を変換
      $( $yticks[i] ).text( tickFormatter(item.metricsFormat, tick) );
    }
    // Y軸のゼロ値は非表示
    $( $yticks[0] ).text('');
  };
  $.jqplot.postDrawHooks.push(detailPostDraw);

  // ★jqplot描画
  var squareBar = jQuery . jqplot( 'detail_graph', graph_data, setYaxisLimit(options, format));

  // jqplot再描画
  squareBar.replot(tickopt);

  // ウインドウリサイズが発生したらイベントを発生
  var timer = false;
  $(window).off('resize').on('resize', function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
      console.log('detail resized');
      // pass in resetAxes: true option to get rid of old ticks and axis properties
      // which should be recomputed based on new plot size.
      squareBar.replot();
    }, 200);
  });
}
