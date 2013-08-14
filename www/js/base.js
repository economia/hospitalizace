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
        pocetHospitalizovanych: +row.HOSP,
        skupina: row.KOD.substr(0, 2) + "00"
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
    var hospitalizace, diagnozy, skupiny, displayBySkupiny;
    hospitalizace = arg$[0], diagnozy = arg$[1], skupiny = arg$[2];
    displayBySkupiny = function(){
      var currentHospitalizaceIndex, rows;
      currentHospitalizaceIndex = 0;
      return rows = skupiny.map(function(skupina){
        var sum, sumYears, row, key$, sumYearsArray, res$, index, count;
        sum = 0;
        sumYears = {};
        for (;;) {
          row = hospitalizace[currentHospitalizaceIndex];
          if (!row || row.skupina !== skupina.kod) {
            break;
          }
          sum += row.pocetHospitalizovanych;
          sumYears[key$ = row.rok] == null && (sumYears[key$] = 0);
          sumYears[row.rok] += row.pocetHospitalizovanych;
          currentHospitalizaceIndex++;
        }
        res$ = [];
        for (index in sumYears) {
          count = sumYears[index];
          res$.push({
            year: index,
            count: count
          });
        }
        sumYearsArray = res$;
        return {
          title: skupina.nazev,
          sum: sum,
          sumYears: sumYearsArray
        };
      });
    };
    return console.log(displayBySkupiny());
  });
}).call(this);
