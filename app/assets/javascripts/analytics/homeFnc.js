function plotHomeGraphDummy() {
  $('#loading').addClass('hide');
  // $('#fm_graph').addClass('hide');

  var data = [
    [0.4, 0.5, 1, {
        color: "#7f7f7f"
    }],
    [0.4, 0.4, 1, {
        color: "#7f7f7f"
    }],
    [0.2, 0.5, 1, {
        color: "#7f7f7f"
    }],
    [0.2, 0.5, 1, {
        color: "#7f7f7f"
    }]
  ];

  // var data = [ [0.4, 0.5, 1] ];

  plotGraphHome([data], []);
}
