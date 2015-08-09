function initDatepicker() {
  var to = new Date();
  var from = new Date(to.getTime() - 1000 * 60 * 60 * 24 * 14);
  var init_text = fmt(from)+' - '+fmt(to);

  // Datepicker は複数設定させないようにする
  if ( $('#datepicker-calendar').children().length == 0 ) {
    $('#datepicker-calendar').DatePicker({
      inline: true,
      calendars: 3,
      mode: 'range',
      current: new Date(to.getFullYear(), to.getMonth() - 1, 1),
      onChange: function(dates, el) {
        // from と to が選択されてから処理を実行する
        if ( fmt(dates[0]) != fmt(dates[1]) ) {
          var text = fmt(dates[0])+' - '+fmt(dates[1]);
          $('#date-range-field span').text(text); // update the range display
          $("input[name='content[date]']")
            .val(text)
            .change(); // update the form date
        }
      }
    });
  }
}

function bindDatepickerOperation() {
  $('#date-range').click(function(event){
    event.stopPropagation();
  });
}

// 日付計算
var calc = function(datestr, p, day) {
  var dt = new Date(datestr);
  switch(p) {
    case '+' :
    dt.setDate(dt.getDate() + day);
    break;
    case '-' :
    dt.setDate(dt.getDate() - day);
    break;
  }
  return dt;
}

// 日付フォーマット
var fmt = function(dt) {
  var year = dt.getFullYear();
  var month = dt.getMonth() + 1;
  var day = dt.getDate();

  if ( month < 10 ) {
  　　month = '0' + month;
  }
  if ( day < 10 ) {
  　　day = '0' + day;
  }
  var str = year + '/' + month + '/' + day;
  return str;
}

// カレンダーの位置を調整
var chgPos = function(input, inst, elm) {
  var cal = inst.dpDiv;
  var top  = elm.offset().top + elm.outerHeight();
  var left = elm.offset().left;
  setTimeout(function() {
    cal.css({
      'top' : top,
      'left': left
    });
   }, 10);
}

// 日付リンクの期間設定を入力ダイアログへ反映させる
function addRangeToDatePicker() {
  var v = $("a#jrange").text(), d, f, t;

  d = v.split('-');

   f = '20' + d[0];
   t = '20' + d[1];

  $('input.fromd').datepicker('setDate', f);
  $('input.tod').datepicker('setDate', t);
}

