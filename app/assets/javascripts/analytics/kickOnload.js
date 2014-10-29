// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  // ホーム画面に遷移した場合、
  // ajaxイベントを実施する
  if ($('title').text().indexOf('ホーム') == 0) {

    // 2014/10/29 ログイン直後に期間設定ダイアログを表示させるよう改修
    $( "#onlogin-dialog" ).dialog('open');

    // if ( $('input[name="prev_page"]').val() ) {
    //   var wd = $('input[name="prev_page"]').val();
    // } else {
    //   var wd = '全体';
    // }

    // var txt = 'div#narrow a:contains(' + wd + ')';

    // // 本番環境ではDOMツリーの構築より早くコマンドが実行されてしまうため、１秒待つ
    // //  おそらくターボリンクスのせい
    // setTimeout( function(){ $(txt).trigger('click'); }, 1000);
  }
});
