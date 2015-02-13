// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベントを定義する

$(window).load(function() {
  if (isTitleHome()) {
    if (location.hash) {
      locationHashChanged();
    } else {
      if (gon.history_hash) {
        changeLocationHash(gon.history_hash);
      } else {
        changeLocationHash('all');
      }
    }
  }
});
