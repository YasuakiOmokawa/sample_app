// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベントを定義する

$(window).load(function() {
  if (isTitleHome()) {
    if (location.hash) {
      $("a[href=" + location.hash + "]").click();
    } else {

      if (gon.history_hash) {
        $("a[href=" + '#' + gon.history_hash + "]").click();
        location.hash = '#' + gon.history_hash;
      } else {
        $('a[href="#all"]').click();
      }

    }
  }
});

function chkAnalyzePageOnLogin() {
  var page_class;
  if ( $('input[name="prev_page"]').val() ) {
    page_class = $('input[name="prev_page"]').val();
  } else {
    page_class = '.all';
  }
  return page_class;
}

function getAnalyzeTriggerAtHome(page_name) {
    return trigger_btn = $('div#pnt').find(page_name);
}

function kickAnalyzeTrigger(trigger_btn) {
    trigger_btn.trigger('click');
}

function analyzeHomePerPage() {
  var page_name = chkAnalyzePageOnLogin();
  var trigger_btn = getAnalyzeTriggerAtHome(page_name);
  kickAnalyzeTrigger(trigger_btn);
}
