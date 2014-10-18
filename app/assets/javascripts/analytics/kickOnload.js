// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  // ホーム画面以外からホームに遷移した場合、
  // ajaxイベントを実施する
  if ($('title').text().indexOf('ホーム') == 0 && $('input[name="prev_pagetitle"]').val().indexOf('ホーム') == 0) {
    var wd = '全体';
    var txt = 'div#narrow a:contains(' + wd + ')';

    // 本番環境ではDOMツリーの構築より早くコマンドが実行されてしまうため、１秒待つ
    //  おそらくターボリンクスのせい
    setTimeout( function(){ $(txt).trigger('click'); }, 1000);
  }
});