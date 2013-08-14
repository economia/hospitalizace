(function(){
  var loadHospitalizace, this$ = this;
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
  async.parallel([loadHospitalizace], function(err, arg$){
    var hospitalizace;
    hospitalizace = arg$[0];
    return console.log(hospitalizace);
  });
}).call(this);
