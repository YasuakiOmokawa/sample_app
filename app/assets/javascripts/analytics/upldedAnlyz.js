$(function(){
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
  * Datepicker 操作のスイッチクラス
  */
  var DatepickerUtil = new function() {
    var self = function DatepickerUtil() {
      this.elem = "a#jrange";
    };

    self.prototype = {
      constructor: self

      ,on: function on() {
        $(document).on('click', this.elem, openDatepicker);
      }

      ,off: function off() {
        $(document).off('click', this.elem);
      }
    };

    return self;
  };

  /**
  * CV選択ボックス操作のスイッチクラス
  */
  var SelectCvUtil = new function() {
    var self = function SelectCvUtil() {
      this.elem = "select#cvselect";
    };

    self.prototype = {
      constructor: self

      ,show: function show() {
        $(this.elem).show();
      }

      ,hide: function hide() {
        $(this.elem).hide();
      }
    };

    return self;
  };

  /**
   * ダイアログのエラー操作用共通クラス
   */
  var ErrorUtil = new function() {
    var self = function ErrorUtil(params) {
      this.model = params.model;
      this.frm = params.frm;
      this.msg = params.msg;
      this.dialogs = params.dialogs;
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
        var idialog = this.dialogs, imodel = this.model, ifrm = this.frm, imsg = this.msg;
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
   * #uplded-anlyz-active-dialog操作クラス
   * @extends ErrorUtil
   */
  var UtilUpldedAnlyzStatusActiveDialog = new function() {
    var self = function UtilUpldedAnlyzStatusActiveDialog(params) {
      ErrorUtil.call(this, params);
    };

    var uber = ErrorUtil.prototype;

    self.prototype = extend(uber, {
      constructor: self

      ,onsuccess: function onsuccess(event, xhr) {
        uber.onsuccess.call();
        var ifrm = this.frm, idialog = this.dialogs;
        $(ifrm).on('ajax:success', function(event, xhr) {
          $(idialog).dialog('close');
          console.log('カスタム分析開始');

          // アップロードファイルの from, to を設定
          $("#from").val( xhr.from );
          $("#to").val( xhr.to );

          // アップロードファイルの名前を設定
          $("#custom-trigger").remove();  // 表示のリセット
          $('#uplded_anlyz_status-inactive-form')
            .before(
              '<span id="custom-trigger">' +
              xhr.upload_file_name +
              '<br>でカスタム分析を実行中です</span>'
            );

          // ファイルid を設定
          $('input[name="custom_file_id"]').val(xhr.content_id);

          // 期間設定のhidden inputへ設定
          setRange();

          if (isTitleHome()) {
            changeLocationHash(getLocationHashPage());
          } else {
            $('a#set').trigger('click');
          }

          // カスタム分析解除ダイアログオープン
          uASInactiveDialogOpen();

          // datepickerリンクの無効化
          var datepickerutil = new DatepickerUtil();
          datepickerutil.off();

          // CV選択ボックスを隠す
          var selectcvutil = new SelectCvUtil();
          selectcvutil.hide();
        });
      }
    });
    return self;
  };

  /**
   * #uplded-anlyz-inactive-dialog操作クラス
   * @extends ErrorUtil
   */
  var UtilUpldedAnlyzStatusInactiveDialog = new function() {
    var self = function UtilUpldedAnlyzStatusInactiveDialog(params) {
      ErrorUtil.call(this, params);
    };

    var uber = ErrorUtil.prototype;

    self.prototype = extend(uber, {
      constructor: self

      ,onsuccess: function onsuccess() {
        uber.onsuccess.call();
        var ifrm = this.frm, idialog = this.dialogs;
        $(ifrm).on('ajax:success', function(event, xhr) {

          $(idialog).dialog('close');

          // datepickerリンクの有効化
          var datepickerutil = new DatepickerUtil();
          datepickerutil.on();

          // CV選択ボックスを表示
          var selectcvutil = new SelectCvUtil();
          selectcvutil.show();

          // ファイルid を解除
          $('input[name="custom_file_id"]').val('');
        });
      }
    });
    return self;
  };

  function initUASActiveDialog() {
    // ダイアログ変数
    var UAS_DIALOG = "#uplded_anlyz_status-active-dialog";

    var model = UAS_DIALOG.replace(/-dialog/, '');
    params = {
      model: model,
      frm: model + "-form",
      msg: model + "-error-message",
      dialogs: UAS_DIALOG
    };
    var uas = new UtilUpldedAnlyzStatusActiveDialog(params);
    uas.onerror();
    uas.onsuccess();
    uas.onbefore();

    $('#open-' + UAS_DIALOG.replace(/#/, '')).click(function() {
      $(UAS_DIALOG).dialog('open');
    });
  }

  function setUASActiveDialog() {
    // ダイアログ変数
    var UAS_DIALOG = "#uplded_anlyz_status-active-dialog";

    // ダイアログ準備
    $(UAS_DIALOG).dialog({
      closeOnEscape: true,
      autoOpen: false,
      draggable: false,
      dialogClass: 'jquery-ui-' + UAS_DIALOG.replace(/#/, ''),
      modal: true,
      height: 150,
    });

    // ダイアログ初期化
    initUASActiveDialog();
  }

  function initUASInactiveDialog() {
    // ダイアログ変数
    var UAS_DIALOG = "#uplded_anlyz_status-inactive-dialog";

    var model = UAS_DIALOG.replace(/-dialog/, '');
    params = {
      model: model,
      frm: model + "-form",
      msg: model + "-error-message",
      dialogs: UAS_DIALOG
    };
    var uas = new UtilUpldedAnlyzStatusInactiveDialog(params);
    uas.onerror();
    uas.onsuccess();
    uas.onbefore();
  }

  function setUASInactiveDialog() {
    // ダイアログ変数
    var UAS_DIALOG = "#uplded_anlyz_status-inactive-dialog",
    class_name = 'jquery-ui-' + UAS_DIALOG.replace(/#/, '');

    // ダイアログ準備
    $(UAS_DIALOG).dialog({
      closeOnEscape: false,
      autoOpen: false,
      draggable: false,
      dialogClass: class_name,
      modal: false,
      height: 44,
      position: {
        my: "left top",
        at: "left top",
      },
      create: function(event, ui) {
        // ダイアログの位置を固定させる
        $(event.target).parent().css('position', 'fixed');
      },
      open  : function() {
        // ダイアログの強制フォーカスを外す
        $(this).find('input, textarea').blur();
      },
   });

    // タイトルバーを表示させない
    $('.' + class_name + " div.ui-dialog-titlebar").hide();

    // ダイアログ初期化
    initUASInactiveDialog();
  }

  function uASInactiveDialogOpen() {
      $("#uplded_anlyz_status-inactive-dialog").dialog('open');
  }

  function ifCustomAnlyz() {
    if ( $("#custom-trigger").length > 0)  {
      // カスタム分析解除ダイアログオープン
      uASInactiveDialogOpen();

      // datepickerリンクの無効化
      var datepickerutil = new DatepickerUtil();
      datepickerutil.off();

      // CV選択ボックスを隠す
      var selectcvutil = new SelectCvUtil();
      selectcvutil.hide();
    }
  }

  // 期間設定ダイアログをオープン
  function openDatepicker() {
    $( "#dialog-form" ).dialog('open');
  }

  // 期間設定リンクへ、ダイアログオープン関数をバインド
  var datepickerutil = new DatepickerUtil();
  datepickerutil.on();

  setUASActiveDialog();
  setUASInactiveDialog();
  ifCustomAnlyz();

});
