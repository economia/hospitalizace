(function(){
  var loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, this$ = this;
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
  loadKraje = function(cb){
    var this$ = this;
    return d3.csv("../kraje.csv", function(err, data){
      return cb(err, data);
    });
  };
  async.parallel([loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje], function(err, arg$){
    var hospitalizace, diagnozy, skupiny, kraje_raw, kraje, i$, len$, ref$, id, nazev, getRowsBySkupiny, draw;
    hospitalizace = arg$[0], diagnozy = arg$[1], skupiny = arg$[2], kraje_raw = arg$[3];
    kraje = {};
    for (i$ = 0, len$ = kraje_raw.length; i$ < len$; ++i$) {
      ref$ = kraje_raw[i$], id = ref$.id, nazev = ref$.nazev;
      kraje[id] = {
        nazev: nazev
      };
    }
    getRowsBySkupiny = function(){
      var currentHospitalizaceIndex, rows;
      currentHospitalizaceIndex = 0;
      return rows = skupiny.map(function(skupina){
        var sum, sumYears, sumKraje, row, key$, sumYearsArray, res$, index, count, sumKrajeArray;
        sum = 0;
        sumYears = {};
        sumKraje = {};
        for (;;) {
          row = hospitalizace[currentHospitalizaceIndex];
          if (!row || row.skupina !== skupina.kod) {
            break;
          }
          sum += row.pocetHospitalizovanych;
          sumYears[key$ = row.rok] == null && (sumYears[key$] = 0);
          sumYears[row.rok] += row.pocetHospitalizovanych;
          sumKraje[key$ = row.kraj] == null && (sumKraje[key$] = 0);
          sumKraje[row.kraj] += row.pocetHospitalizovanych;
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
        res$ = [];
        for (index in sumKraje) {
          count = sumKraje[index];
          res$.push({
            kraj: kraje[index],
            count: count
          });
        }
        sumKrajeArray = res$;
        return {
          title: skupina.nazev,
          sum: sum,
          sumYears: sumYearsArray,
          sumKraje: sumKrajeArray
        };
      });
    };
    draw = function(rows){
      var container, x$;
      container = d3.select(".container");
      rows = container.selectAll(".row").data(rows).enter().append("div").attr('class', 'row');
      x$ = rows.append("h2");
      x$.text(function(it){
        return it.title;
      });
      return x$;
    };
    return draw(getRowsBySkupiny());
  });
}).call(this);
