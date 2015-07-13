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
        case 'number': return RoundValueUnderOne(val);
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
    xaxis: 'xaxis',
    yaxis: 'yaxis',
    y: tick,
    shadow: false,
    shadowAlpha: 0,
    shadowAngle: 0,
    color: 'gray',
    dashPattern: [4,4],
    lineCap: 'square',
    lineWidth: 0.3
  };

  return data;
}

// x軸（日付）の値に合わせてグラフ背景色を変更
var resetXbgc = function(nm, dt, yval) {

  var data = {}, bgc, d = dt + 1;

  if ( (nm == 'day_sun') || (nm == 'day_hol') )  {
    bgc = "#FFEEFF";
  } else if (nm == 'day_sat') {
    bgc = "#EEFFFF";
  }

  data['line'] = {
    xaxis: 'xaxis',
    yaxis: 'yaxis',
    start : [d - 0.5, yval],
    stop : [d + 0.5, yval],
    lineWidth: 1000,
    color: bgc,
    shadow: false,
    lineCap : 'butt'
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
                        + item.metricsJp + ': ' + tickFormatter(gon.format_string, kv[1])
                      + '</div>';

  return format;
}

var calcYMax = function(graph_data) {
  return Math.max.apply(null, graph_data[0].map(function(v) {
      return Number(v[1]);
    } )
  );
}

//+ Jonas Raoni Soares Silva
//@ http://jsfromhell.com/math/dot-line-length [rev. #1]

dotLineLength = function(x, y, x0, y0, x1, y1, o){
    function lineLength(x, y, x0, y0){
        return Math.sqrt((x -= x0) * x + (y -= y0) * y);
    }
    if(o && !(o = function(x, y, x0, y0, x1, y1){
        if(!(x1 - x0)) return {x: x0, y: y};
        else if(!(y1 - y0)) return {x: x, y: y0};
        var left, tg = -1 / ((y1 - y0) / (x1 - x0));
        return {x: left = (x1 * (x * tg - y + y0) + x0 * (x * - tg + y - y1)) / (tg * (x1 - x0) + y0 - y1), y: tg * left - tg * x + y};
    }(x, y, x0, y0, x1, y1), o.x >= Math.min(x0, x1) && o.x <= Math.max(x0, x1) && o.y >= Math.min(y0, y1) && o.y <= Math.max(y0, y1))){
        var l1 = lineLength(x, y, x0, y0), l2 = lineLength(x, y, x1, y1);
        return l1 > l2 ? l2 : l1;
    }
    else {
        var a = y0 - y1, b = x1 - x0, c = x0 * y1 - y0 * x1;
        return Math.abs(a * x + b * y + c) / Math.sqrt(a * a + b * b);
    }
};

// メイン処理
function jqplotDetail() {

  var graph_data = setArr(gon.data_for_graph_display);

  // グラフのオプション
  var options = {
      seriesColors: ["#e6b422", "#1e50a2"],
      seriesDefaults: {
        shadow: false,
      },
      axesDefaults: {
          tickOptions: {
            fontSize: '9pt',
            fontFamily: 'ヒラギノ角ゴ Pro W3',
          },
      },
      // グラフ幅の調整
      // gridPadding: { top: 1, bottom: 1, left: 30, right: 1 },
      gridPadding: { top: 1, bottom: 1, left: 1, right: 1 },
      series:[
            // １つ目の項目の設定
          {
              // renderer: jQuery . jqplot . BarRenderer,
              fillToZero: true,
              negativeSeriesColors: ["#e6b422"],
              rendererOptions: {
                lineWidth: 1,
                // barPadding: 0,
                // barMargin: 5
              },
          },
      ],
      axes: {
          xaxis: {
              renderer: jQuery . jqplot . CategoryAxisRenderer,
              tickOptions: {
                fontSize: '6.5pt',
                showGridline: false,
                // 項目の延長線は削除（なんかヒゲみたいで嫌）
                markSize: 0
              },
          },
          yaxis: {
              numberTicks: 0,
              min: 0.0,
              // max: 0.0,
              // pad: 1,
              tickOptions: {
                // 自作関数でフォーマットする
                formatter: tickFormatter,
                showGridline: true,
                markSize: 0,
              },
          },
      },
      // マウスオーバー時の数値表示
      highlighter: {
          show: true,
          fadeToolTip: false,
          tooltipContentEditor: getPointInfo,
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
  $.jqplot.postDrawHooks.push(function() {

      // x軸（日付）の処理
      // var ymax_value = $yticks.last().text(); // 土日祝の背景を塗りつぶすときに使う
      var ymax_value = calcYMax(this.data);
      var $xtics = $('.jqplot-xaxis-tick');

      for ( var i=0; i < $xtics.length; i++) {

        // var day_type = graph_data[i].day_type;
        var day_type = this.data[0][i][2];
        var background_graph_color;

        // 土曜日の部分背景を青、日祝なら赤に変更
        if (day_type != 'day_on') {
          background_graph_color = resetXbgc(day_type, i, ymax_value);
          tickopt.canvasOverlay.objects.push(background_graph_color);
        }

        // 土曜日なら文字列を青、日祝なら文字列を赤に変更
        if (day_type == 'day_sun' || day_type == 'day_hol') {
          $( $xtics[i] ).css("color", "red");
        } else if (day_type == 'day_sat') {
          $( $xtics[i] ).css("color", "blue");
        }

      }


      // グラフのy座標へ水平線を設定
      // var tick, dt;
      // var $yticks = $('.jqplot-yaxis-tick');

      // for(var i=0; i < $yticks.length; i++) {

      //   // 目盛りの値を変換
      //   tick = $( $yticks[i] ).text();
      //   // console.log(tick);

      //   // y軸を再設定
      //   dt = resetYtick(tick);
      //   tickopt.canvasOverlay.objects.push(dt);
      // }

  });

  // ★jqplot描画
  var squareBar = jQuery . jqplot( 'detail_graph', graph_data, setYaxisLimit(options, gon.format_string));

  // jqplot再描画
  squareBar.replot(tickopt);

  // ウインドウリサイズが発生したらイベントを発生
  var timer = false;
  $(window).on('resize', function() {
    if (timer !== false) {
      clearTimeout(timer);
    }
    timer = setTimeout(function() {
        console.log('resized');
        // pass in resetAxes: true option to get rid of old ticks and axis properties
        // which should be recomputed based on new plot size.
        squareBar.replot();
    }, 50);
  });
};
