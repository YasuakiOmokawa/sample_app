/**
* URL クエリパラメータ操作クラス
*/
var Query = new function() {
  var self = function Query() {
    this._query = location.search.slice(1);
  };

  self.prototype = {
    constructor: self

    ,replaceCategory: function replaceCategory(category) {

      function replacer(match, p1, p2, p3, offset, string) {
        return p1+category;
      }
      return this._query.replace(/(category=).*$/, replacer);
    }

    ,prv_split: function prv_split() {
      return this._query.split("&");
    }

    ,getQuery: function getQuery() {
      return this._query;
    }

    ,createObject: function createObject() {
      var p = {};
      jQuery.each($(this.prv_split()), function(k, v) {
        var tmp = v.split("=");
        if ( tmp[0].match(/from|to/) ) {
          tmp[1] = replaceAll(tmp[1], '-', '/');
        }
        p[tmp[0]] = decodeURIComponent(tmp[1]);
      });
      return p;
    }

    ,forSettingsCompare: function forSettingsCompare() {
      var l_obj = this.createObject();
      return l_obj.from+l_obj.to+l_obj.cv_num;
    }
  };
  return self;
};

/**
* セッションストレージ操作クラス
*/
var Settings = new function() {
  var self = function Settings(obj) {
    this._obj = obj;
  };

  self.prototype = {
    constructor: self

    ,createQueryParameter: function createQueryParameter() {

      var l_param = '';

      // パラメータの生成
      jQuery.each(this._obj, function(key, val) {
        if ( key.match(/from|to/) ) {
          val = replaceAll(val, '/', '-');
        }
        l_param += encodeURIComponent(key)+"="+encodeURIComponent(val) + "&";
      });
      // 終端の'&'を取り除く
      return l_param.slice(0, -1);
    }

    ,forSettingsCompare: function forSettingsCompare() {
      return this._obj.from+this._obj.to+this._obj.cv_num;
    }
  };
  return self;
};
