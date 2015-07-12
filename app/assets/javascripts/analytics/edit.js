$(function(){

  // パスワード変更画面のフォーム値の入力を監視
  setInterval(function() {
    if ($("#user_password").val() && $("#user_password_confirmation").val()) {
      $("#cancel").addClass("hide");
      $("#change").removeClass("hide");
    } else {
      $("#cancel").removeClass("hide");
      $("#change").addClass("hide");
    }
  }, 100);
});
