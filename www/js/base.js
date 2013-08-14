(function(){
  var loadHospitalizace, loadDiagnozy, loadSkupiny, this$ = this;
  d3.selectAll(".fallback").remove();
  loadHospitalizace = function(cb){
    var ssv, this$ = this;
    ssv = d3.dsv(";", "text/csv");
    return ssv("../hospitalizace.csv", function(row){
      return {
        kod: row.KOD,
        rok: row.ROK,
        pohlavi: row.POHL === "1" ? "muz" : "zena",
        vek: row.VEKKAT,
        kraj: +row.KRAJ,
        hosp: +row.HOSP
      };
    }, function(err, data){
      return cb(err, data);
    });
  };
  loadDiagnozy = function(cb){
    var this$ = this;
    return d3.csv("../diagnozy.csv", function(err, data){
      return cb(err, data);
    });
  };
  loadSkupiny = function(cb){
    var this$ = this;
    return d3.csv("../skupiny.csv", function(err, data){
      return cb(err, data);
    });
  };
  async.parallel([loadHospitalizace, loadDiagnozy, loadSkupiny], function(err, arg$){
    var hospitalizace, diagnozy, skupiny;
    hospitalizace = arg$[0], diagnozy = arg$[1], skupiny = arg$[2];
    return console.log(skupiny);
  });
}).call(this);
