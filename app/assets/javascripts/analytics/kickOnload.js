$(window).load(function() {


  if (isTitleHome()) {

    if (location.hash) {
      console.log('window load イベント実行');
      setTimeout("locationHashChanged()", 500);
    } else {
      if (gon.history_hash) {
        console.log('グラフへ戻る　イベントが発生しました');
        changeLocationHash(gon.history_hash);
      } else {
        changeLocationHash('all');
      }
    }

  }
});
