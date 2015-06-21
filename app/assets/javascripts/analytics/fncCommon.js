$(document).bind('keydown', 'esc', function() {
  return false;
});

$(document).ready(function() {
  replaceContentParentAttr();
  EventsOnSettingUI();

  // Wiselinks 設定
  window.wiselinks = new Wiselinks( $('@data-role'), { //  layouts/_wiselinks.html.erb で更新される場所を指定
    // html4_normalize_path: false, // IE9 で無限リロードされるバグの解消
    html4: true,
    target_missing: 'exception',
  });

  $(document).off('page:loading').on('page:loading', function(event, $target, render, url) {
    console.log("Loading: " + url + " to " + $target.selector + " within '" + render + "'");
    // start loading animation
    $('#loading').removeClass('hide');
    $('#spinner').removeClass('hide');
  });

  $(document).off('page:redirected').on('page:redirected', function(event, $target, render, url) {
    console.log("Redirected to: "+ url);
    // start loading animation
    $('#loading').removeClass('hide');
    $('#spinner').removeClass('hide');
  });

  $(document).off('page:always').on('page:always', function(event, xhr, settings) {
    console.log("Wiselinks page loading completed");
    // stop loading animation
    $('#loading').addClass('hide');
    $('#spinner').addClass('hide');
    replaceContentParentAttr();
    EventsOnSettingUI();
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

function EventsOnSettingUI() {

  initDatepicker();
  bindDatepickerOperation();

  // ファイル選択ダイアログの起動判定範囲を広げる
  $("#cv li").last().on("click", 'input', function(evt) {
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

      $("input[name='content[cv_num]']").val( cv_data );
      highlightSelectedCV( cv_data );
      setFormViaAjax();

      // ファイルダイアログのオープン判定
      if (cv_data === "file") {
        $('#content_upload_file').click();
      }
    }
  });
}

function setFormViaAjax() {
  $("#submit")
    .replaceWith('<a id="submit" href="javascript:void(0)" onclick="execFormSubmit()">設定</a>');
}

function execFormSubmit() {
  $('form#new_content').ajaxSubmit({
    beforeSubmit: function() {
      removeUploadError();
    },
    success: function(obj) {
      removeUploadError();
      sessionStorage.setItem( obj.storage_key, JSON.stringify(obj) );
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

  // 空ファイルでなければ処理を実行する
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
  }
}
