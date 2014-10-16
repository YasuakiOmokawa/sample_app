// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  // ホーム画面に遷移した場合、
  // ajaxイベントを実施する
  if ($('title').text().indexOf('ホーム') == 0) {
    var wd = '全体';
    var txt = 'div#narrow a:contains(' + wd + ')';
    $(txt).trigger('click');
  }
});
