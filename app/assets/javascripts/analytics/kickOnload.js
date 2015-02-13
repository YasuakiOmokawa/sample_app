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
