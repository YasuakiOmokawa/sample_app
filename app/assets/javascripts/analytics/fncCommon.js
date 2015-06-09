function setEventOnChangeCVName() {
  $('select#cvselect').change(function() {
      $('input[name="cv_num"]').val($(this).val());

      if (isTitleHome()) {
        changeLocationHash(getLocationHashPage());
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

function getAnalyzedPageName() {
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
  var self = function HomeOverlay() {};
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
  var self = function SelectOverlay() {};
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

function getTargetAction(e) {
  return $(e.target).attr("name");
}

function getFormAction() {
  return $('form[name="narrowForm"]').attr('action');
}

function setFormAction(ref) {
  $('form[name="narrowForm"]').attr("action", ref);
}

function getHomeHistoryParameter() {

  if ( $('input[name="history_from"]').val() ) {
    $('#from').val($('input[name="history_from"]').val());
  }

  if ($('input[name="history_to"]').val()) {
    $('#to').val($('input[name="history_to"]').val());
  }

  if ($('input[name="history_cv_num"]').val()) {
    $('input[name="cv_num"]').val($('input[name="history_cv_num"]').val());
  }

  $('input[name="shori"]').val(0);
  $('input[name="device"]').val('all');
  $('input[name="visitor"]').val('all');
  $('input[name="day_type"]').val('all_day');
  $('#narrow_select').val("");
}

function backToHome(e) {
  var acts = getFormAction().split('/');
  $('input[name="hash"]').val(acts[3]);

  var act_ref = e.attr("name");
  setFormAction(act_ref);

  getHomeHistoryParameter();

  $('a#set').trigger('click');

}

function setBackToHome() {
  $('#bk a').click(function() {
    backToHome($(this));
  });
}

function triggerBackToHome() {
  $('#bk a').trigger('click');
}

$(document).bind('keydown', 'esc', function() {
  return false;
});

// // Bind to StateChange Event with historyjs-rails gem
// // Note: We are using statechange instead of popstate
// History.Adapter.bind(window,'statechange',function(){
//     // Note: We are using History.getState() instead of event.state
//     var State = History.getState();
// });

function setHomeHistoryParameter() {
  if (gon.history_from) {
    $('input[name="history_from"]').val(gon.history_from);
  }

  if (gon.history_to) {
    $('input[name="history_to"]').val(gon.history_to);
  }

  if (gon.history_cv_num) {
    $('input[name="history_cv_num"]').val(gon.history_cv_num);
  }

}

// Wiselinks 設定
$(document).ready(function() {
  window.wiselinks = new Wiselinks( $('@data-role'), { //  layouts/_wiselinks.html.erb で更新される場所を指定
    html4: true,
    target_missing: 'exception'
  });

  $(document).off('page:loading').on('page:loading', function(event, $target, render, url) {
    console.log("Loading: " + url + " to " + $target.selector + " within '" + render + "'");
    // code to start loading animation
  });

  $(document).off('page:redirected').on('page:redirected', function(event, $target, render, url) {
    console.log("Redirected to: "+ url);
    // code to start loading animation
  });

  $(document).off('page:always').on('page:always', function(event, xhr, settings) {
    console.log("Wiselinks page loading completed");
    // code to stop loading animation
    initDatepicker();
    bindDatepickerOperation();
    triggerDatepicker();
    triggerFileField();
  });

  $(document).off('page:done').on('page:done', function(event, $target, status, url, data) {
    console.log("Wiselinks status: '" + status + "'");
  });

  $(document).off('page:fail').on('page:fail', function(event, $target, status, url, error, code) {
    console.log("Wiselinks status: '" + status + "'");
    // code to show error message
  });
});

$(document).ready(function() {

  // ページタイトルに応じて、絞り込み要素をフィルタする
  // var ol = overlayFactory($('title').text());
  // if (typeof ol != "undefined") {
  //   ol.overlayNarrow(ol);
  //   overlayOnResize(ol);
  // }

  setBackToHome();

  // setEventOnChangeCVName();

  // グラフに表示する項目のプルダウンを選択したときのイベント
  // $('select#graphicselect').change(function() {
  //   $('input[name="graphic_item"]').val($(this).val());
  //   $('a#set').trigger('click');
  // });

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
        $('#ltfm table#highlight tr:nth-child(2) td:nth-child(1)').css("color", "red");
        break;
      case 'セッション':
        // 数値
        $('#ltfm table#highlight tr:nth-child(3) td:nth-child(1)').css("color", "red");
        break;
      case 'ユーザー':
        // 数値
        $('#ltfm table#highlight tr:nth-child(4) td:nth-child(1)').css("color", "red");
        break;
      case '平均PV数':
        // 目標値
        $('#ltfm table#highlight tr:nth-child(5) td:nth-child(1)').css("color", "red");
        break;
      case '平均滞在時間':
        // 目標値
        $('#ltfm table#highlight tr:nth-child(6) td:nth-child(1)').css("color", "red");
        break;
      case '新規ユーザー':
        // 目標値
        $('#ltfm table#highlight tr:nth-child(7) td:nth-child(1)').css("color", "red");
        break;
      case 'リピーター':
        // 目標値
        $('#ltfm table#highlight tr:nth-child(8) td:nth-child(1)').css("color", "red");
        break;
      case '直帰率':
        // 数値
        $('#ltfm table#highlight tr:nth-child(9) td:nth-child(1)').css("color", "red");
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

  // ホーム画面までの履歴を保持
  // setHomeHistoryParameter();
});
