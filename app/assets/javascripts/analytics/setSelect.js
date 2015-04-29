$(function(){
  function setSelect(val) {
    var $obj = $('a#content-delete-link');
    var link = $obj.attr("href");
    var tmp = link.replace(/\?.*$/, '');
    var rep = tmp + '?content_id=' + encodeURIComponent(val);
    $obj.attr("href", rep);
  }

  // セレクトボックス選択後
  $('select#content_id').change(function() {
    setSelect($(this).val());
  });

  // 初回実施
  setSelect($('select#content_id').val());
});
