// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベント
$(window).load(function() {

  if ($('title').text().indexOf('ホーム') == 0) {

    // キャッシュデータの取得
    var cached_obj;
    cached_obj = cacheResult(cached_obj, false, 'GET', 'zentai');

    if (cached_obj) {

      createBubbleWithParts(cached_obj);

      markPageBtn('全体');

    } else {

      $( "#onlogin-dialog" ).dialog('open');

    }

  }
});
