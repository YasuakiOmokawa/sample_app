// DOMツリー（htmlタグ）が全て読み込まれた後に実施されるイベントを定義する

$(window).load(function() {
  if (isTitleHome()) {
    if (location.hash) {
      locationHashChanged();
    } else {
      changeLocationHash('all');
    }
  }
});
