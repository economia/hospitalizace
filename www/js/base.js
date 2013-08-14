(function(){
  var lineHeight, linePadding, barChartWidth, numOfYears, loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadObyvatele, loadGeoJsons, this$ = this;
  lineHeight = 200;
  linePadding = 20;
  barChartWidth = 200;
  numOfYears = 5;
  d3.selectAll(".fallback").remove();
  new Tooltip().watchElements();
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
  loadObyvatele = function(cb){
    var ssv, this$ = this;
    ssv = d3.dsv(";", "text/csv");
    return ssv("../obyv.csv", function(row){
      return {
        rok: row.ROK,
        pohlavi: row.POHL === "1" ? "muz" : "zena",
        vek: row.VEKKAT,
        kraj: +row.KRAJ,
        pocet: +row.OBYV
      };
    }, function(err, data){
      return cb(err, data);
    });
  };
  loadGeoJsons = function(cb){
    var this$ = this;
    return d3.json("../kraje.geojson", function(err, data){
      return cb(err, data);
    });
  };
  async.parallel([loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadGeoJsons, loadObyvatele], function(err, arg$){
    var hospitalizace, diagnozy, skupiny, kraje_raw, kraje_geojson, obyvatele, kraje, i$, len$, ref$, id, nazev, obyvateleAverage, ref1$, geometry, recalculateKrajeObyv, getRowsBySkupiny, draw, drawSums, drawBarCharts, drawMap, formatNumber;
    hospitalizace = arg$[0], diagnozy = arg$[1], skupiny = arg$[2], kraje_raw = arg$[3], kraje_geojson = arg$[4], obyvatele = arg$[5];
    kraje = {};
    for (i$ = 0, len$ = kraje_raw.length; i$ < len$; ++i$) {
      ref$ = kraje_raw[i$], id = ref$.id, nazev = ref$.nazev;
      obyvateleAverage = 0;
      kraje[id] = {
        nazev: nazev,
        obyvateleAverage: obyvateleAverage
      };
    }
    for (i$ = 0, len$ = (ref$ = kraje_geojson.features).length; i$ < len$; ++i$) {
      ref1$ = ref$[i$], geometry = ref1$.geometry, id = ref1$.id;
      kraje[id].geometry = geometry;
    }
    recalculateKrajeObyv = function(){
      var i$, ref$, len$, ref1$, rok, pohlavi, vek, kraj, pocet, results$ = [];
      for (i$ = 0, len$ = (ref$ = obyvatele).length; i$ < len$; ++i$) {
        ref1$ = ref$[i$], rok = ref1$.rok, pohlavi = ref1$.pohlavi, vek = ref1$.vek, kraj = ref1$.kraj, pocet = ref1$.pocet;
        results$.push(kraje[kraj].obyvateleAverage += pocet / numOfYears);
      }
      return results$;
    };
    getRowsBySkupiny = function(){
      var currentHospitalizaceIndex, rows;
      currentHospitalizaceIndex = 0;
      return rows = skupiny.map(function(skupina){
        var sum, sumYears, sumKraje, id, row, sumYearsArray, res$, index, count, sumKrajeArray;
        sum = 0;
        sumYears = {
          "2007": 0,
          "2008": 0,
          "2009": 0,
          "2010": 0,
          "2011": 0
        };
        sumKraje = {};
        for (id in kraje) {
          sumKraje[id] = 0;
        }
        for (;;) {
          row = hospitalizace[currentHospitalizaceIndex];
          if (!row || row.skupina !== skupina.kod) {
            break;
          }
          sum += row.pocetHospitalizovanych;
          sumYears[row.rok] += row.pocetHospitalizovanych;
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
    draw = function(rowsData){
      var sums, container, rows, x$;
      rowsData.sort(function(a, b){
        return b.sum - a.sum;
      });
      sums = rowsData.map(function(it){
        return it.sum;
      });
      container = d3.select(".container");
      rows = container.selectAll(".row").data(rowsData).enter().append("div").attr('class', 'row');
      x$ = rows.append("h2");
      x$.text(function(row, index){
        return (index + 1) + ". " + row.title;
      });
      drawSums(sums, rows);
      drawBarCharts(rows, rowsData);
      return drawMap(rows, rowsData);
    };
    drawSums = function(sumValues, rows){
      var scale, heightScale, x$, y$, z$, z1$;
      scale = d3.scale.sqrt().domain([0, sumValues[0]]).range([1, 5]);
      heightScale = d3.scale.sqrt().domain([0, sumValues[0]]).range([30, 110]);
      x$ = rows.append("div");
      x$.attr('class', 'sum');
      x$.attr('data-tooltip', function(it){
        return escape("Průměrně <strong>" + formatNumber(Math.round(it.sum / 5)) + "</strong> hospitalizací ročně");
      });
      y$ = x$.append('div');
      y$.attr('class', 'valueContainer');
      z$ = y$.append("span");
      z$.attr('class', 'value');
      z$.text(function(it){
        if (it.sum > 1000) {
          return Math.round(it.sum / 5000) + "";
        } else {
          return "méně než";
        }
      });
      z$.style('font-size', function(it){
        return scale(it.sum) + "em";
      });
      z1$ = y$.append('span');
      z1$.html("<br />tisíc hospitalizací");
      y$.style('height', function(it){
        return heightScale(it.sum) + "px";
      });
      return x$;
    };
    drawBarCharts = function(rows, rowsData){
      var maxValue, i$, len$, row, j$, ref$, len1$, count, x$, scale, columnWidth, y$, z$, z1$;
      maxValue = -Infinity;
      for (i$ = 0, len$ = rowsData.length; i$ < len$; ++i$) {
        row = rowsData[i$];
        for (j$ = 0, len1$ = (ref$ = row.sumYears).length; j$ < len1$; ++j$) {
          count = ref$[j$].count;
          if (count > maxValue) {
            maxValue = count;
          }
        }
      }
      x$ = scale = d3.scale.linear();
      x$.domain([0, maxValue]);
      x$.range([1, lineHeight - 3 * linePadding]);
      columnWidth = barChartWidth / numOfYears;
      y$ = rows.append("div").attr('class', 'years').style('bottom', function(data){
        var values, max, bottom;
        values = data.sumYears.map(function(it){
          return it.count;
        });
        max = scale(Math.max.apply(Math, values));
        bottom = ((lineHeight - 2 * linePadding) - max) / 2;
        return bottom + "px";
      }).selectAll(".year").data(function(it){
        return it.sumYears;
      }).enter().append('div');
      y$.attr('class', 'year');
      y$.attr('data-tooltip', function(data){
        return escape("<strong>" + formatNumber(data.count) + "</strong> hospitalizací");
      });
      y$.style('width', (columnWidth - 1) + "px");
      y$.style('left', function(data, index){
        return index * columnWidth + "px";
      });
      z$ = y$.append('div');
      z$.attr('class', 'value');
      z$.style('height', function(yearData, yearIndex, rowIndex){
        return scale(yearData.count) + "px";
      });
      z1$ = z$.append('div');
      z1$.attr('class', 'popis');
      z1$.text(function(it){
        return it.year;
      });
      return y$;
    };
    drawMap = function(rows, rowsData){
      var tstMax, getKrajValue, color, centroid, projection, geoPath, x$, svg, y$;
      tstMax = -Infinity;
      getKrajValue = function(item, krajIndex, rowIndex){
        var data, krajSum, value;
        data = rowsData[rowIndex];
        krajSum = data.sumKraje[krajIndex];
        if (!krajSum.kraj.obyvateleAverage) {
          return 0;
        }
        value = ((krajSum != null ? krajSum.count : void 8) || 0) / (krajSum.kraj.obyvateleAverage || 1);
        if (value > tstMax) {
          tstMax = value;
        }
        return value;
      };
      color = d3.scale.linear().domain([0, 0.189 / 4, 0.189 / 2, 0.189 / 4 * 3, 0.189]).range(['#FFFFB2', '#FECC5C', '#FD8D3C', '#F03B20', '#BD0026']);
      centroid = d3.geo.centroid(kraje_geojson);
      projection = d3.geo.mercator().center(centroid).scale(2000).translate([135, 100]);
      geoPath = d3.geo.path().projection(projection);
      x$ = svg = rows.append("svg");
      x$.attr('class', 'map');
      y$ = svg.selectAll('path').data(function(it){
        return it.sumKraje.map(function(it){
          return {
            count: it.count,
            obyvateleAverage: it.kraj.obyvateleAverage,
            geometry: it.kraj.geometry,
            title: it.kraj.nazev,
            type: 'Feature'
          };
        });
      }).enter().append('path');
      y$.attr('d', geoPath);
      y$.attr('data-tooltip', function(item, krajIndex, rowIndex){
        var data, krajSum;
        data = rowsData[rowIndex];
        data = rowsData[rowIndex];
        krajSum = data.sumKraje[krajIndex];
        return escape(krajSum.kraj.nazev + ": <strong>" + formatNumber(Math.round(krajSum.count / krajSum.kraj.obyvateleAverage * 100000)) + "</strong> hospitalizací na 100&nbsp;000 obyvatel");
      });
      y$.attr('fill', function(){
        return color(getKrajValue.apply(this, arguments));
      });
      return console.log(tstMax);
    };
    formatNumber = function(num){
      num = num.toString();
      if (num.length > 3) {
        num = num.substr(0, num.length - 3) + "&nbsp;" + num.substr(-3);
      }
      return num;
    };
    recalculateKrajeObyv();
    return draw(getRowsBySkupiny());
  });
}).call(this);
