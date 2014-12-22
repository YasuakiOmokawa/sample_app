// マイナス値があるか判定するフラグ
var chk_minus = 0;

function zeroSuppressedDateFormat(data) {
  date = Number(data.substr(4, 2)).toString() + "/" + Number(data.substr(6, 2)).toString();
  return date;
}

// コントローラから渡されたパラメータをグラフ描画用の配列に加工
var setArr = function(data) {
    var arr_metrics = [], arr_cv = [], dts;
    for (var i in data) {
      dts = zeroSuppressedDateFormat(i.toString());

      arr_metrics.push( [ dts, gon.data_for_graph_display[i][0] ]);
      arr_cv.push( [ dts, gon.data_for_graph_display[i][1] ]);

      // // gap値にマイナスがあるか判定
      // if ( String(gon.data_for_graph_display[i][0]).indexOf('-') == 0 ) {
      //   chk_minus = 1;
      // }
    };
    arr.push(arr_metrics, arr_cv);
}

// 表示する値の種類によって、グラフのY軸（左側）のフォーマットを変更
// ロジック変更が発生したら、update_table.rb chg_time()　もチェックすること

var tickFormatter = function (format, val) {
    switch(format) {
        case 'percent': return val.toFixed(1) + '%';
        case 'number': return val.toFixed(1);
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
    yaxis: 'y2axis',
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
    yaxis: 'y2axis',
    start : [d - 0.5, yval],
    stop : [d + 0.5, yval],
    lineWidth: 1000,
    color: bgc,
    shadow: false,
    lineCap : 'butt'
  };
  return data;
}

var arr = [];
setArr(gon.data_for_graph_display);

// グラフのオプション
var options = {
    seriesColors: ["#e6b422", "#1e50a2"],
    seriesDefaults: {
      shadow: false,
    },
    axesDefaults: {
        tickOptions: {
          fontSize: '9pt',
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
              fontSize: '6.5pt',
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
            numberTicks: 11,
            pad: 1,
            tickOptions: {
              // 自作関数でフォーマットする
              formatter: tickFormatter,
              showGridline: false,
            },
        },
        y2axis: {
            autoscale: true,
            numberTicks: 11,
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

function setYaxisLimit(options, format) {
  if (format === 'percent') {
    options.axes.yaxis.min = 0;
    options.axes.yaxis.max = 100;
  }
  return options;
}

// // gap値にマイナスがあれば、y軸の目盛りの数を変更
// if (chk_minus == 1) {
//   options.axes.yaxis.numberTicks = 10;
//   options.axes.y2axis.numberTicks = 10;
// }

// メイン処理
jQuery( function() {

  // 再描画用のオプション
  var tickopt = {
    canvasOverlay: {
      show: true,
      objects: [],
      yaxis: {},
      y2axis: {}
    }
  };

  // jqplot描画後に実行する操作（jqplot描画前に書くこと）
  $.jqplot.postDrawHooks.push(function() {
      $('.jqplot-axis.jqplot-x2axis').hide();

      // x軸（日付）の処理
      var ymax_value = $('.jqplot-y2axis-tick').last().text(); // 土日祝の背景を塗りつぶすときに使う
      for ( var i=0; i < $('.jqplot-xaxis-tick').length; i++) {

        var text = $( $('.jqplot-xaxis-tick')[i] ).text();
        var date = 'td[data-dflg]:contains(' + String(text) + ')';
        var name = $(date).attr("data-dflg");
        var dt;
        // console.log(name);

        // 土曜日の部分背景を青、日祝なら赤に変更
        if (name != 'day_on') {
          dt = resetXbgc(name, i, ymax_value);
          tickopt.canvasOverlay.objects.push(dt);
        }

        // 土曜日なら文字列を青、日祝なら文字列を赤に変更
        if (name == 'day_sun' || name == 'day_hol') {
          $( $('.jqplot-xaxis-tick')[i] ).css("color", "red");
        } else if (name == 'day_sat') {
          $( $('.jqplot-xaxis-tick')[i] ).css("color", "blue");
        }

        // 32日以上データがあるなら平日は非表示にする　← 2014/9/3 指定期間を1か月に限定したのでコメントアウト
        // if ( $('.jqplot-xaxis-tick').length >= 32 ) {
        //   if (name == 'day_on') {
        //     $( $('.jqplot-xaxis-tick')[i] ).text('');
        //   }
        // }

      }

      // グラフの下部マージンを変更
      $('#square.jqplot-target').css("margin-bottom", "20px");

      // y軸の罫線を後ろに移動
      $('.jqplot-overlayCanvas-canvas').css("z-index", -1);

  });

    // ★jqplot描画
  var squareBar = jQuery . jqplot( 'gh', arr, setYaxisLimit(options, gon.format_string));

  // グラフのy座標へ水平線を設定
  var yticks = $('.jqplot-y2axis-tick'), tick, dt;

  for(var i=0; i < yticks.length; i++) {

    // 目盛りの値を変換
    // tick = setYgridnum(gon.format_string, $(yticks[i]).text()); // y2axisを使用するようにしたため、変換は不要
    tick = $(yticks[i]).text();
    // console.log(tick);

    // y軸を再設定
    dt = resetYtick(tick);
    tickopt.canvasOverlay.objects.push(dt);
  }
  // jqplot再描画
  squareBar.replot(tickopt);
});
