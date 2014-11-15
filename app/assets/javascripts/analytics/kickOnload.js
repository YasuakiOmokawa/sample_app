// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  if ($('title').text().indexOf('ホーム') == 0) {

    analyzeHomePerPage();

  }
});

function chkAnalyzePageOnLogin() {
  var page_name;
  if ( $('input[name="prev_page"]').val() ) {
    page_name = addSpecialCharacters( $('input[name="prev_page"]').val() );
  } else {
    page_name = '全体';
  }
  return page_name;
}

function getAnalyzeTriggerAtHome(page_name) {
    return trigger_btn = 'div#narrow a:contains(' + page_name + ')';
}

function kickAnalyzeTrigger(trigger_btn) {
    // 本番環境ではDOMツリーの構築より早くコマンドが実行されてしまうため、１秒待つ
    //  おそらくターボリンクスのせい
    setTimeout( function(){ $(trigger_btn).trigger('click'); }, 1000);
}

function analyzeHomePerPage() {

  var page_name = chkAnalyzePageOnLogin();

  var trigger_btn = getAnalyzeTriggerAtHome(page_name);

  kickAnalyzeTrigger(trigger_btn);

}
