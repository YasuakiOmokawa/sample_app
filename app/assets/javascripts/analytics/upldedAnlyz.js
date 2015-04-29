/**
 * Object.createの拡張関数( javascriptクラスの継承に使う)
 */
function extend(o) {
  var f = extend.f, i, len, n, prop;
  f.prototype = o;
  n = new f;
  for (i=1, len=arguments.length; i<len; ++i) {
    for (prop in arguments[i]) {
      n[prop] = arguments[i][prop];
    }
  }
  return n;
}
extend.f = function(){};

/**
 * ダイアログのエラー操作用共通クラス
 */
var ErrorUtil = new function() {
  var self = function ErrorUtil(params) {
    this.model = params.model;
    this.frm = params.frm;
    this.msg = params.msg;
    this.dialog = params.dialog;
  };
  self.prototype = {
    constructor: self
    ,onerror: function onerror() {
      var imodel = this.model, ifrm = this.frm, imsg = this.msg;
      $(ifrm).on("ajax:error", function(event, xhr) {
        $(imsg).removeClass('hide').show();
        var errors = JSON.parse(xhr.responseText).errors;
        $.each(errors, (function(k, v) {
          $("#errors ul").append("<li>" + '*' + k + v + "</li>");
          $(imodel + '_' + k).closest(".form-group").addClass("has-error");
        }));
      });
    }
    ,onsuccess: function onsuccess() {
      var imodel = this.model, ifrm = this.frm, imsg = this.msg, idialog = this.dialog;
      $(ifrm).on("ajax:success", function() {
        $(imsg).hide();
        $("#errors ul").empty();
        $(ifrm).find(".form-group").removeClass("has-error");
        $(idialog).dialog('close');
      });
    }
    ,onbefore: function onbefore() {
      var imodel = this.model, ifrm = this.frm, imsg = this.msg;
      $(ifrm).on("ajax:before", function() {
        $(imsg).hide();
        $("#errors ul").empty();
        $(ifrm).find(".form-group").removeClass("has-error");
      });
    }
  };
  return self;
};

/**
 * #uplded-anlyz-dialog操作クラス
 * @extends ErrorUtil
 */
var UtilUpldedAnlyzStatusDialog = new function() {
  var self = function UtilUpldedAnlyzStatusDialog(params) {
    ErrorUtil.call(this, params);
  };

  var uber = ErrorUtil.prototype;

  self.prototype = extend(uber, {
    constructor: self

    ,onsuccess: function onsuccess() {
      uber.onsuccess.call();
      var ifrm = this.frm, idialog = this.dialog;
      $(ifrm).on('ajax:success', function() {
        console.log('分析開始');
      });
    }
  });
  return self;
};


$(function(){

  // ダイアログ変数
  var UAS_DIALOG = '#uplded_anlyz_status-dialog';

  // ダイアログ準備(analyze)
  $(UAS_DIALOG).dialog({
    closeOnEscape: true,
    autoOpen: false,
    draggable: false,
    dialogClass: 'jquery-ui-' + UAS_DIALOG.replace(/#/, ''),
    modal: true,
    height: 150,
  });

  $('#open-' + UAS_DIALOG.replace(/#/, '')).click(function() {
    var model = UAS_DIALOG.replace(/-dialog/, '');
    params = {
      model: model,
      frm: model + "-form",
      msg: model + "-error-message",
      dialog: UAS_DIALOG,
    };
    var uas = new UtilUpldedAnlyzStatusDialog(params);
    uas.onerror();
    uas.onsuccess();
    uas.onbefore();

    $(UAS_DIALOG).dialog('open');
  });

  // ダイアログ変数
  var C_DIALOG = '#content-dialog';

  // ダイアログ準備(analyze)
  $(C_DIALOG).dialog({
    closeOnEscape: true,
    autoOpen: false,
    draggable: false,
    dialogClass: 'jquery-ui-' + C_DIALOG.replace(/#/, ''),
    modal: true,
    width: 800
  });

  $('#open-' + C_DIALOG.replace(/#/, '')).click(function() {
    var model = C_DIALOG.replace(/-dialog/, '');
    params = {
      model: model,
      frm: model + "-form",
      msg: model + "-error-message",
      dialog: C_DIALOG,
    };
    var eu = new ErrorUtil(params);
    eu.onerror();
    eu.onsuccess();
    eu.onbefore();

    $(C_DIALOG).dialog('open');
  });


  // ダイアログ準備(content)
  // $C_DIALOG.dialog({
  //   closeOnEscape: true,
  //   autoOpen: false,
  //   draggable: false,
  //   dialogClass: 'jquery-ui-upload-dialog',
  //   modal: true,
  //   width: 800
  //   // height: 500,
  // });


  // $('#open-upload-dialog').click(function() {
  //   $C_DIALOG.dialog('open');
  // });

  // ダイアログ実行結果分岐

//     model = "#uplded_anlyz_status";
// $(model + "-update-form")

//   var model = "#uplded_anlyz_status";
//   var $FORM = $("#uplded_anlyz_status-form"),
//         MSGBASE = "#uplded_anlyz_status";
//         $MSG = $(MSGBASE + "-error-message");

//   $FORM.on("ajax:error", function(event, xhr) {
//     $MSG.removeClass('hide').show();
//     var errors = JSON.parse(xhr.responseText).errors;
//     $.each(errors, (function(k, v){
//       $("#errors ul").append("<li>" + '*' + k + v + "</li>");
//       $("#uplded_anlyz_status_" + k).closest(".form-group").addClass("has-error");
//     }));
//   }).on("ajax:success", function() {
//     $MSG.hide();
//     $("#errors ul").empty();
//     $FORM.find(".form-group").removeClass("has-error");
//     $A_DIALOG.dialog('close');
//     console.log('分析開始!');

//   }).on("ajax:before", function() {
//     $MSG.hide();
//     $("#errors ul").empty();
//     $FORM.find(".form-group").removeClass("has-error");
//   });

});
