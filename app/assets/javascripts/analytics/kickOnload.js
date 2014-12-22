// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  if ($('title').text().indexOf('ホーム') == 0) {

    // 本番環境ではDOMツリーの構築より早くコマンドが実行されてしまうため、１秒待つ
    //  おそらくターボリンクスのせい
    setTimeout( function(){ analyzeHomePerPage(); }, 1000);

  }
});

function chkAnalyzePageOnLogin() {
  var page_name;
  if ( $('input[name="prev_page"]').val() ) {
    page_name = $('input[name="prev_page"]').val();
  } else {
    page_name = '.all';
  }
  return page_name;
}

function getAnalyzeTriggerAtHome(page_name) {
    // return trigger_btn = 'div#pnt a:contains(' + page_name + ')';
    return trigger_btn = $('div#pnt').find(page_name);
}

function kickAnalyzeTrigger(trigger_btn) {
    trigger_btn.trigger('click');
}

function analyzeHomePerPage() {

  var page_name = chkAnalyzePageOnLogin();

  // bubbleCreateAtTabLink(page_name);

  var trigger_btn = getAnalyzeTriggerAtHome(page_name);

  kickAnalyzeTrigger(trigger_btn);

}
