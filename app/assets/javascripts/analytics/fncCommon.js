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
    $("#error_msg").addClass("hide");
    $('#loading').removeClass('hide');
    $('#spinner').removeClass('hide');
  });

  $(document).off('page:redirected').on('page:redirected', function(event, $target, render, url) {
    console.log("Redirected to: "+ url);
    // start loading animation
    $("#error_msg").addClass("hide");
    $('#loading').removeClass('hide');
    $('#spinner').removeClass('hide');
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
    if (code == 500) {
      alert('セッションが切れました。再ログインしてください');
    }
  });

  // ajax中に別ページへの通常リクエストが発生したらajax消去
  $("body").off("ajaxSend").on("ajaxSend", function(c, xhr) {
      $( window ).bind( 'beforeunload', function() {
          xhr.abort();
      })
  });
});

function eventsOnMenu() {

  var setting_data = sessionStorage.getItem( "setting_key" ),
    $date = $("#replacement-date"), $cv_name = $("#replacement-cv_name"),
    content_url = $("#content-link").text();

  // 分析条件が設定された場合の処理
  if (setting_data) {
    // メニューの期間、CV表示を変更
    var setting_obj = JSON.parse(setting_data);
    // 期間表示
    $date
      .text(setting_obj.from+" - "+setting_obj.to)
      .removeClass("set");
    // CV表示
    $cv_name
      .text(setting_obj.cv_name)
      .removeClass('set');
    // 分析開始リンクの有効化判定
    if (isNewSettings()) {
      $("#atics")
        .attr('id', "atics_s")
        .addClass("yes");
    } else {
      $("#atics_s")
       .attr('id', "atics")
       .removeClass("yes");
    }
  }

  // 分析リンクがクリックされたときの処理
  $(".base-anlyz, .home-anlyz").off('click').on("click", function() {
    if ($(this).hasClass('yes')) {

      // ローディングモーションを表示
      $("#error_msg").addClass("hide");
      $('#loading').removeClass('hide');
      $('#spinner').removeClass('hide');
      $('#now-loading').removeClass('hide');

      console.log( '分析済チェックを開始');
      var category = $(this).attr("id"),
        params = createAnlyzParameter(category);

      // 分析結果がキャッシュ済か確認する
      $.ajax({
        url: $("#chk-cache-link").text(),
        dataType: 'json',
        data: params
      })
      .done(function(data, textStatus, jqXHR) {
        console.log( '分析済チェック完了');
        // キャッシュ済の場合
        if (data.is_cached) {
          // ホーム画面の遷移リクエスト発行
          console.log( '分析済です');
          var new_url = $('#home-link').text() + '?' + params.for_get_request;
          window.wiselinks.page.load(new_url, "@data-role", 'partial');
        } else {
          // 分析を開始
          console.log( '分析結果がありません');
          startHomeAnlyz(category);
        }
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        addErrorMessage('分析済チェックエラーが発生しました： '
          + String(errorThrown));
      });
    }
  });

  // 設定画面へのリンクがクリックされたときの処理
  $date.off('click').on('click', function() {
    location.href = content_url
  });
  $cv_name.off('click').on('click', function() {
    location.href = content_url
  });
}

function isNewSettings() {
  var setting_data = sessionStorage.getItem( "setting_key" );
  if (location.href.match(/contents/)) {
    // 設定画面であればfalse
    return false;
  } else if (location.search && setting_data) {
    var query = new Query(),
      settings = new Settings(JSON.parse(setting_data));

    // 対象のカテゴリをグレーアウト
    $(".dummy-category").remove();
    var $elem = $(document.getElementById(
      query.createObject().category));
    $elem
      .after('<div class="dummy-category">'+$elem.text()+'</div>')
      .addClass("hide");

    // 分析開始以外の分析リンクをクリック可能にする
    $(".home-anlyz").addClass(("yes"));

    // 分析設定が更新されていればtrue
    if (query.forSettingsCompare() === settings.forSettingsCompare()) {
      return false;
    } else {
      return true;
    }
  } else if (setting_data) {
    // 分析設定がされていればtrue
    return true;
  } else if (!location.search){
    // まだ分析が実行されていなければfalse
    return false;
  } else {
    return false;
  }
}

function replaceAll(expression, org, dest){
  return expression.split(org).join(dest);
}

function createAnlyzParameter(category) {
  if (category == "atics_s") {
    return createParameterWithSessionStorage();
  } else {
    return createParameterWithURL(category);
  }
}

function createParameterWithSessionStorage() {
  var obj = {},
    setting_obj = JSON.parse(sessionStorage.getItem( "setting_key" ));

  setting_obj.category = 'all';
  delete setting_obj.cv_name;
  var settings = new Settings(setting_obj);

  obj.for_get_request = settings.createQueryParameter();
  obj.for_anlyz = setting_obj;
  return obj;
}

function createParameterWithURL(category) {
  var query = new Query(), obj = {};

  obj.for_get_request = query.replaceCategory(category);
  obj.for_anlyz = query.createObject();
  obj.for_anlyz.category = category;
  return obj;
}

function eventsOnSettingUI() {

  var $inputDate = $("input[name='content[date]']");
  initDatepicker();
  bindDatepickerOperation();

  // 選択してくださいリンクの無効化
  $("#replacement-date").attr("href", "javascript:void(0)");
  $("#replacement-cv_name").attr("href", "javascript:void(0)");

  // CV設定のファイル選択エリアの処理
  $("#cv li").last().on("click", 'input', function(evt) {
    $(evt.target).parent().find("a").click();
  });

  // ファイルが選択されたときの処理
  $("#content_upload_file").on("change", onFileSelect);

  // 「キャンセル」がクリックされたときの処理
  $("#cancell").on("click", function() {
    history.back(-1);
  });

  // 「選択」がクリックされたときの処理
  $("#cv").on("click", "a", function(evt) {

    var $target = $(evt.currentTarget);

    // 選択済みであれば何も処理しない
    if (! $target.hasClass("selected") ) {
      var cv_data = $target.attr("class");

      console.log('cv_data set : '+ cv_data);

      highlightSelectedCV( cv_data );

      // 選択されたのがオンラインデータであれば以下の処理を行う
      if (cv_data != "file") {
        // ファイル名の表示を削除する
        $("#file").val('');
        // file_fieldの値を削除する
        $('#content_upload_file').val('');

        // if 期間データの入力値が不正な値である場合
        if ( $inputDate.val() && $("#date-range-field span").text() === "選択してください" ) {
          // データをリセット
          $inputDate.val('');
        // 期間データが有効な値である場合
        } else if ($("#date-range-field span").text() != "選択してください") {
          // 期間データをセット
          $inputDate.val($("#date-range-field span").text());
        }
      } else {
        // オフラインデータであればファイルダイアログをオープン
        // 期間設定にはダミー値を設定
        $inputDate.val("dummy");
        $('#content_upload_file').click();
      }

      // CV値を設定
      $("input[name='content[cv_num]']").val( cv_data );
    }
  });

  // 設定画面のフォーム値を監視
  setInterval(function() {
    // ファイル選択が既にされていた場合は、何もしない
    if ($("input[name='content[cv_num]']").val() === 'dummy') {
      return;
    }
    // 期間とCVどちらも設定されていれば有効化
    if ($("input[name='content[date]']").val() && $("input[name='content[cv_num]']").val() ) {
      $(".cancel-submit").addClass('hide');
      $(".dummy-submit").addClass("hide");
      $(".real-submit").removeClass("hide");
    } else {
      $(".cancel-submit").addClass('hide');
      $(".dummy-submit").removeClass("hide");
      $(".real-submit").addClass("hide");
    }
  }, 100);

  // 遷移時点で設定済みの値があれば反映させる
  if ( !$("#replacement-date").hasClass('set') ) {
    var settedDate = $("#replacement-date").text();
    $("#date-range-field span").text(settedDate);
    $inputDate.val(settedDate);
  }
  if ( !$("#replacement-cv_name").hasClass('set') ) {
    var settedCV = $("#replacement-cv_name").text();
    var $selectedTarget = $( $("#cv").find("li:contains('"+settedCV+"')").find('a') );

    if ($selectedTarget.length >= 1) {
      $("input[name='content[cv_num]']").val( $selectedTarget.attr('class') );
      highlightSelectedCV( $selectedTarget.attr('class') );
    } else {
      // ファイル選択の場合は、設定リンクをキャンセルリンクへイミテーションさせて対応する
      $("input[name='content[cv_num]']").val('dummy');
      highlightSelectedCV('file');
      $("#file").val(settedCV);
      $(".dummy-submit").addClass("hide");
      $(".cancel-submit").removeClass('hide');
    }
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
      if (xhr.status == 500) {
        alert("セッションが切れました。再ログインしてください");
      } else {
        $("#content-active-error-message").removeClass('hide');
        var errors = JSON.parse(xhr.responseText).errors;
        $.each(errors, (function(k, v) {
          $("#errors ul").append("<li>" + '*' + k + v + "</li>");
          $("content" + '_' + k).closest(".form-group").addClass("has-error");
        }));
      }
    }
  });
}

function removeUploadError() {
  $("#content-active-error-message").addClass('hide');
  $("#errors ul").empty();
}

function onFileSelect() {
  var regex = /\\|\\/, file_name = $('#content_upload_file').val();
  var array = file_name.split(regex);

  // 選択されたファイルが空ファイルでなければ処理を実行する
  if (array[array.length - 1].length > 0) {
    $("#file").val( array[array.length - 1] );
  }
}

function replaceContentParentAttr() {
  if ( location.href.match(/contents|detail/) ) {
    console.log("css condition is not home");
    $('#back').removeClass('hide');
  } else {
    console.log("css condition is home");
    $('#back').addClass('hide');
  }
}

function highlightSelectedCV(cv_num) {
  var $cves = $("#cv li"), finder = "."+cv_num;

  // グレーアウトされている「選択」リンクの色を元に戻す
  $cves.find("a").removeClass('selected');

  // 「選択」リンクの色を変更
  $cves.find(finder).addClass('selected');
}

// 小数点一位以下四捨五入
function RoundValueUnderOne(val) {
  return Math.round( Number(val) * 10) / 10;
}

getFunctionName = function(f){
    return 'name' in f
        ? f.name
        : (''+f).replace(/^\s*function\s*([^\(]*)[\S\s]+$/im, '$1');
};

resetPostDrawHooks = function(){
  var len = $.jqplot.postDrawHooks.length;
  if (len === 3) {
    $.jqplot.postDrawHooks.pop();
  }
}
