$(document).bind('keydown', 'esc', function() {
  return false;
});

$(document).ready(function() {
  eventsOnMenu();
  replaceContentParentAttr();
  if ( location.href.match(/contents/) ) {
    eventsOnSettingUI();
  }

  // Wiselinks 設定
  window.wiselinks = new Wiselinks( $('@data-role'), { //  layouts/_wiselinks.html.erb で更新される場所を指定
    // html4_normalize_path: false, // IE9 で無限リロードされるバグの解消
    html4: true,
    target_missing: 'exception',
  });

  $(document).off('page:loading').on('page:loading', function(event, $target, render, url) {
    console.log("Loading: " + url + " to " + $target.selector + " within '" + render + "'");
    // start loading animation
    if ( location.href.match(/contents/) ) {
      $('#loading').removeClass('hide');
      $('#spinner').removeClass('hide');
    }
  });

  $(document).off('page:redirected').on('page:redirected', function(event, $target, render, url) {
    console.log("Redirected to: "+ url);
    // start loading animation
    if ( location.href.match(/contents/) ) {
      $('#loading').removeClass('hide');
      $('#spinner').removeClass('hide');
    }
  });

  $(document).off('page:always').on('page:always', function(event, xhr, settings) {
    console.log("Wiselinks page loading completed");
    // 必要な関数を読み込む
    eventsOnMenu();
    replaceContentParentAttr();
    if ( location.href.match(/contents/) ) {
      eventsOnSettingUI();
    }
  });

  $(document).off('page:done').on('page:done', function(event, $target, status, url, data) {
    console.log("Wiselinks status: '" + status + "'");
  });

  $(document).off('page:fail').on('page:fail', function(event, $target, status, url, error, code) {
    console.log("Wiselinks status: '" + status + "'");
    // code to show error message
  });

  // ajax中に別ページへの通常リクエストが発生したらajax消去
  $("body").bind("ajaxSend", function(c, xhr) {
      $( window ).bind( 'beforeunload', function() {
          xhr.abort();
      })
  });
});

function eventsOnMenu() {

  // 「戻る」がクリックされたときの処理
  $("#back").on("click", function() {
    history.back(-1);
  });

  var setting_data = sessionStorage.getItem( "setting_key" );
  var base_anlyz_params = '';
  if (setting_data) {
    // メニューの期間、CV表示を変更
    var setting_obj = JSON.parse(setting_data);
    // 期間表示
    $("#replacement-date")
      .text(setting_obj.from+" - "+setting_obj.to)
      .removeClass("set")
      .attr("href", $("#content-link").text());
    // CV表示
    $("#replacement-cv_name")
      .text(setting_obj.cv_name)
      .removeClass('set')
      .attr("href", $("#content-link").text());
    // 分析開始リンク
    $("#atics").attr('id', "atics_s");

    // ホーム分析用のパラメータ生成
    jQuery.each(setting_obj, function(key, val) {
      if ( key.match(/from|to/) ) {
        val = replaceAll(val, '/', '-');
      }
      base_anlyz_params += encodeURIComponent(key)+"="+encodeURIComponent(val) + "&";
    });

    // カテゴリ付与
    base_anlyz_params += encodeURIComponent("category")+"="+encodeURIComponent("all");
  }

  // 「分析開始」がクリックされたときの処理
  $("#atics_s").on("click", function() {
    location.hash = base_anlyz_params;
  });

  // hashchangeハンドラの定義
  window.onhashchange = locationHashChanged;
}

function replaceAll(expression, org, dest){
    return expression.split(org).join(dest);
}

function locationHashChanged() {
// var params = pushLocationHash(decodeURIComponent(location.hash).split("#"));
console.log("location.hash is " + location.hash);
// setAnchorParams(params);
bubbleCreateAtTabLink();
}

function eventsOnSettingUI() {

  initDatepicker();
  bindDatepickerOperation();

  // 選択してくださいリンクの無効化
  $("#replacement-date").attr("href", "javascript:void(0)");
  $("#replacement-cv_name").attr("href", "javascript:void(0)");

  // ファイル選択ダイアログの起動判定範囲を広げる
  $("#cv li").last().on("click", 'input', function(evt) {
    $("input[name='content[date]']").val("dummy"); // 期間設定をダミー選択
    $(evt.target).parent().find("a").click();
  });

  // ファイルが選択されたときの処理
  $("#content_upload_file").on("change", displaySelectedFileName);

  // 「キャンセル」がクリックされたときの処理
  $("#cancell").on("click", function() {
    history.back(-1);
  });

  // 「選択」がクリックされたときの処理
  $("#cv").off('click').on("click", "a", function(evt) {

    var $target = $(evt.currentTarget);

    // 選択済みであれば何も処理しない
    if (! $target.hasClass("selected") ) {
      var cv_data = $target.attr("class");

      console.log('cv_data set : '+ cv_data);

      $("input[name='content[cv_num]']")
        .val( cv_data ).change();
      highlightSelectedCV( cv_data );

      // ファイルダイアログのオープン判定
      if (cv_data === "file") {
        $('#content_upload_file').click();
      }
    }
  });

  // 期間、CVどちらかの値が設定された場合の処理
  $("input.parameter").on("change", setFormViaAjax );
}

function setFormViaAjax() {
  // 初期化
  $("#submit")
    .replaceWith('<div id="submit">設定</div>');

  var date = $("input[name='content[date]']").val();
  var cv_num = $("input[name='content[cv_num]']").val();
  // 期間とCVどちらも設定されていれば有効化
  if (date.length > 0 && cv_num.length > 0) {
    $("#submit")
      .replaceWith('<a id="submit" href="javascript:void(0)" onclick="execFormSubmit()">設定</a>');
  }
}

function execFormSubmit() {
  $('form#new_content').ajaxSubmit({
    beforeSubmit: function() {
      removeUploadError();
    },
    success: function(obj) {
      sessionStorage.setItem( "setting_key", JSON.stringify(obj) );
      $("#cancell").click(); // 設定前の画面へ戻る
    },
    error: function(xhr) {
      $("#content-active-error-message").removeClass('hide');
      var errors = JSON.parse(xhr.responseText).errors;
      $.each(errors, (function(k, v) {
        $("#errors ul").append("<li>" + '*' + k + v + "</li>");
        $("content" + '_' + k).closest(".form-group").addClass("has-error");
      }));
    }
  });
}

function removeUploadError() {
  $("#content-active-error-message").addClass('hide');
  $("#errors ul").empty();
}

function displaySelectedFileName() {
  var regex = /\\|\\/, file_name = $('#content_upload_file').val();
  var array = file_name.split(regex);

  // 選択されたファイルが空ファイルでなければ処理を実行する
  if (array[array.length - 1].length > 0) {
    $("input#file")
      .val( array[array.length - 1] );
    // 日付選択カレンダーを非表示にする
    $("#date-range").addClass('hide');
  }
}

function replaceContentParentAttr() {
  if ( location.href.match(/contents|detail/) ) {
    console.log("css condition is not home");
    $('#replace').attr('id', "fm");
    $('li.switch').removeClass('hide');
  } else {
    console.log("css condition is home");
    $('#fm').attr('id', "replace");
    $('li.switch').addClass('hide');
    $('#loading').removeClass('hide');
  }
}


function highlightSelectedCV(cv_num) {
  var $cves = $("#cv li"), finder = "."+cv_num;

  // グレーアウトされている「選択」リンクの色を元に戻す
  $cves.find("a").removeClass('selected');

  // 「選択」リンクの色を変更
  $cves.find(finder).addClass('selected');

  // 選択されたのがオンラインデータであれば以下の処理を行う
  if (cv_num != "file") {
    // 日付選択カレンダーを表示させる
    $("#date-range").removeClass('hide');
    // ファイル名の表示を削除する
    $("input#file").val('');
    // file_fieldの値を削除する
    $('#content_upload_file').val('');
    // 期間データを初期化する
    $("input[name='content[date]']").val("").change();

  }
}
