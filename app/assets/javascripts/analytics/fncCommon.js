function setEventOnChangeCVName() {
  $('select#cvselect').change(function() {
      $('input[name="cv_num"]').val($(this).val());

      if (isTitleHome()) {
        var key = isTargetClicked(getClickedAnalyzeTrigger());
        bubbleCreateAtTabLink(key);
      } else {
        $('a#set').trigger('click');
      }
  });
}

function isTitleHome() {
  if ($('title').text().indexOf('ホーム') == 0) {
    return true;
  } else {
    return false;
  }
}

function getClickedAnalyzeTrigger() {
  return $('#pnt div').attr('class');
}

function isTargetClicked(target) {

  if (typeof target === 'undefined') {
    return 'all';
  } else {
    return target;
  }
}

var HomeOverlay = new function() {
  var self = function HomeOverlay() {

  };

  self.prototype = {
    constructor: self

    ,handler: function handler() {
      $('form div.plainoverlay').css(
        {
          height: '42px',
          cursor: 'auto',
          top: '-14px',
          'min-width': '1200px',
          'background-color': 'white',
          width: '100%',
        }
      );
    }

    ,overlayNarrow: function overlayNarrow(fn) {
      $('span#home-overlay').plainOverlay('show',
        {
          progress: false,
          show: fn.handler
        }
      );
    }

    ,hello: function hello() {
      console.log('hello!');
    }
  };

  return self;
};

var SelectOverlay = new function() {
  var self = function SelectOverlay() {

  };

  self.prototype = {
    constructor: self

    ,handler: function handler() {
      $('form div.plainoverlay').css(
        {
          height: '42px',
          cursor: 'auto',
          top: '-14px',
          'width': '250px',
          'background-color': 'white',
          width: '100%',
        }
      );
    }

    ,overlayNarrow: function overlayNarrow(fn) {
      $('span#select-overlay').plainOverlay('show',
        {
          progress: false,
          show: fn.handler
        }
      );
    }

    ,hello: function hello() {
      console.log('hello!');
    }
  };

  return self;
};

function overlayFactory(title) {
 var postfix = ' | AST';

  switch (title) {
    case 'ホーム' + postfix:
      return new HomeOverlay();
      break;
    case '全体' + postfix:
    case '検索' + postfix:
    case '直接入力/ブックマーク' + postfix:
      return new SelectOverlay();
      break;
    }
}

// ブラウザのウインドウがリサイズされた場合、ホーム画面のオーバーレイcssを更新するイベント
function overlayOnResize(klass) {
  var timer = false;

  $(window).resize(function() {
      if (timer !== false) {
          clearTimeout(timer);
      }
      timer = setTimeout(function() {
          // オーバーレイcssの再設定
          klass.handler();
      }, 200);
  });
}

// 要素の表示、非表示を判定する
$.fn.isVisible = function() {
    return $.expr.filters.visible(this[0]);
};

// チェックボックスのふるまいをラジオボタンと同じする
function likeRadio(obj) {
  var n = obj.attr("name");
  var m = 'input[name=' + n + ']';
  var objs = $(m);
  var f = objs, cnt = 0;
  for(var i=0;i<f.length;i++ ){
    if ( f[i].checked === true ) {
      cnt = cnt + 1;
    }
  }
  if (cnt >= 2) {
    f.prop("checked", false); // 属性値の状態を取得するならpropのほうが良いってさ。。
    obj.prop("checked", true);
    console.log("hello like Radio!");
  }
}

// 指定した要素をフォーム送信ボタンをクリックしたときと同じ動作にする
var evtset = function (at) {
  $('form[name="narrowForm"]').attr("action", at.attr("name"));
  console.log(at);
}
var evtsend = function (at) {
  $('form[name="narrowForm"]').attr("action", at.attr("name"));
  $('a#set').trigger('click');
}

// 期間設定ボックスの初期値を設定
var setRange = function setRange() {
  var from = $('#from').val().substr(2);
  var to = $('#to').val().substr(2);
  var range = from + '-' + to;
  var txt = $('a#jrange').html().split(">");
  txt2 = txt[0] + '>' + range;
  $('a#jrange').html(txt2);
}

$(document).ready(function() {

  // ページタイトルに応じて、絞り込み要素をフィルタする
  var ol = overlayFactory($('title').text());
  if (typeof ol != "undefined") {
    ol.overlayNarrow(ol);
    overlayOnResize(ol);
  }

  // グラフへ戻るを選択したときのイベント
  $('#bk a').click(function() {
    var act = $('form[name="narrowForm"]').attr('action');
    var acts = act.split('/');
    var acts_class = '.' + acts[3];

    $('input[name="shori"]').val(0);
    $('input[name="prev_page"]').val(acts_class);
    evtsend($(this));
  });

  setEventOnChangeCVName();

  // グラフに表示する項目のプルダウンを選択したときのイベント
  $('select#graphicselect').change(function() {
    $('input[name="graphic_item"]').val($(this).val());
    $('a#set').trigger('click');
  });

  // 種類ごとにチェックボックスの複数選択を抑止
  $('input[name=device]').click(function() {
    likeRadio($(this));
  });
  $('input[name=visitor]').click(function() {
    likeRadio($(this));
  });
  $('input[name=day_type]').click(function() {
    likeRadio($(this));
  });

  // ajax中に別ページへの通常リクエストが発生したらajax消去
  $("body").bind("ajaxSend", function(c, xhr) {
      $( window ).bind( 'beforeunload', function() {
          xhr.abort();
      })
  });

  // 絞り込みボタンを押したとき、プログレススピナーを起動する
  $('a#set').click(function(){

    // スピナーの実装
    if ( $('#hd div.spinner').length <= 0) {
      var opts = {
        lines: 13, // The number of lines to draw
        length: 4, // The length of each line
        width: 2, // The line thickness
        radius: 3, // The radius of the inner circle
        corners: 1, // Corner roundness (0..1)
        rotate: 0, // The rotation offset
        direction: 1, // 1: clockwise, -1: counterclockwise
        color: 'white', // #rgb or #rrggbb or array of colors
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: false, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 2e9, // The z-index (defaults to 2000000000)
      };
      var target = $('#hd');
      var spinner = new Spinner(opts).spin();
      target.append(spinner.el);
      $('.spinner').css('margin-top', 2);
    }
  });

  // escボタンを押したとき、プログレススピナーをキャンセルする
  $(window).keydown(function(e){
    if( e.keyCode == 27 ) {
      $('.spinner').remove();
    }
  });

  // 曜日ごとに背景色を変更
  // 土。。薄い青　日、祝。。　薄い赤
  $('td[data-day]').each(function() {

    var dtype = $(this).attr("data-day");

    if ( (dtype == 'day_sun') || (dtype == 'day_hol') )  {
      $(this).css("background-color", "#FFEEFF");
    } else if (dtype == 'day_sat') {
      $(this).css("background-color", "#EEFFFF");
    }
  });

  // ラジオボタンの選択値を保持
  var rdo_dev = gon.radio_device
  var rdo_vst = gon.radio_visitor
  var rdo_day = gon.radio_day
  $('input[name="device"]').val([rdo_dev]);
  $('input[name="visitor"]').val([rdo_vst]);
  $('input[name="day_type"]').val([rdo_day]);

  // プルダウンの選択値を保持
  var nrw_wd = gon.narrow_word
  $('select[name="narrow_select"]').val(nrw_wd);

  // ホーム画面で指定した項目を赤で強調表示する
  // 目標値のある項目は目標の数値。それ以外は数値を強調表示する
  if (gon.red_item) {
    var i = gon.red_item;
    switch (String(i)) {
      case 'PV数':
        // 数値
        $('#ltfm table tr:nth-child(2) td:nth-child(1)').css("color", "red");
        break;
      case 'セッション':
        // 数値
        $('#ltfm table tr:nth-child(3) td:nth-child(1)').css("color", "red");
        break;
      case 'ユーザー':
        // 数値
        $('#ltfm table tr:nth-child(4) td:nth-child(1)').css("color", "red");
        break;
      case '平均PV数':
        // 目標値
        $('#ltfm table tr:nth-child(5) td:nth-child(1)').css("color", "red");
        break;
      case '平均滞在時間':
        // 目標値
        $('#ltfm table tr:nth-child(6) td:nth-child(1)').css("color", "red");
        break;
      case '新規ユーザー':
        // 目標値
        $('#ltfm table tr:nth-child(7) td:nth-child(1)').css("color", "red");
        break;
      case 'リピーター':
        // 目標値
        $('#ltfm table tr:nth-child(8) td:nth-child(1)').css("color", "red");
        break;
      case '直帰率':
        // 数値
        $('#ltfm table tr:nth-child(9) td:nth-child(1)').css("color", "red");
        break;
      }
  }

  // グラフ表示項目の選択値を保持
  var grh_fmt = gon.graphic_item;
  $('select[name="graphicselect"]').val(grh_fmt);
  $('input[name="graphic_item"]').val(grh_fmt);

  // CV種類の選択値を保持
  var cv = gon.cv_num;
  $('select[name="cvselect"]').val(cv);
  $('input[name="cv_num"]').val(cv);

  // 遷移元ページの情報を保持
  var prev_page = gon.prev_page;
  $('input[name="prev_page"]').val(prev_page);

  // プルダウン未選択時の文字色を薄めに変更
  var dColor = '#999999';
  var fColor = '#000000';
  if ( $('#narrow_select').val() == "" ){
    $('#narrow_select').css('color', dColor);
  } else {
    $('#narrow_select').css('color', fColor);
  }
  $('#narrow_select')
    .focus(function() {
      $('#narrow_select').css('color', fColor);
    })
    .blur(function() {
      if ( $('#narrow_select').val() == "" ){
        $('#narrow_select').css('color', dColor);
      } else {
        $('#narrow_select').css('color', fColor);
      }
  });

});
