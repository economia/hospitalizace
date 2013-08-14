(function(){
  var lineHeight, linePadding, barChartWidth, numOfYears, loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadGeoJsons, this$ = this;
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
  loadGeoJsons = function(cb){
    var this$ = this;
    return d3.json("../kraje.geojson", function(err, data){
      return cb(err, data);
    });
  };
  async.parallel([loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadGeoJsons], function(err, arg$){
    var hospitalizace, diagnozy, skupiny, kraje_raw, kraje_geojson, kraje, i$, len$, ref$, id, nazev, ref1$, geometry, getRowsBySkupiny, draw, drawSums, drawBarCharts, drawMap, formatNumber;
    hospitalizace = arg$[0], diagnozy = arg$[1], skupiny = arg$[2], kraje_raw = arg$[3], kraje_geojson = arg$[4];
    kraje = {};
    for (i$ = 0, len$ = kraje_raw.length; i$ < len$; ++i$) {
      ref$ = kraje_raw[i$], id = ref$.id, nazev = ref$.nazev;
      kraje[id] = {
        nazev: nazev
      };
    }
    for (i$ = 0, len$ = (ref$ = kraje_geojson.features).length; i$ < len$; ++i$) {
      ref1$ = ref$[i$], geometry = ref1$.geometry, id = ref1$.id;
      kraje[id].geometry = geometry;
    }
    getRowsBySkupiny = function(){
      var currentHospitalizaceIndex, rows;
      currentHospitalizaceIndex = 0;
      return rows = skupiny.map(function(skupina){
        var sum, sumYears, sumKraje, row, key$, sumYearsArray, res$, index, count, sumKrajeArray;
        sum = 0;
        sumYears = {
          "2007": 0,
          "2008": 0,
          "2009": 0,
          "2010": 0,
          "2011": 0
        };
        sumKraje = {};
        for (;;) {
          row = hospitalizace[currentHospitalizaceIndex];
          if (!row || row.skupina !== skupina.kod) {
            break;
          }
          sum += row.pocetHospitalizovanych;
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
      var scale, x$, y$;
      scale = d3.scale.sqrt().domain([0, sumValues[0]]).range([0, lineHeight - 2 * linePadding]);
      x$ = rows.append("div");
      x$.attr('class', 'sum');
      x$.attr('data-tooltip', function(it){
        return escape("Průměrně <strong>" + formatNumber(Math.round(it.sum / 5)) + "</strong> hospitalizací ročně");
      });
      y$ = x$.append("div");
      y$.attr('class', 'value');
      y$.style('width', function(it){
        return scale(it.sum) + "px";
      });
      y$.style('height', function(it){
        return scale(it.sum) + "px";
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
      x$.range([1, lineHeight - 2 * linePadding]);
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
      var getKrajValue, color, centroid, projection, geoPath, x$, svg, y$;
      getKrajValue = function(item, krajIndex, rowIndex){
        var data, krajSum;
        data = rowsData[rowIndex];
        krajSum = data.sumKraje[krajIndex];
        return (krajSum != null ? krajSum.count : void 8) || 0;
      };
      color = d3.scale.linear().domain([0, 139947 / 4, 139947 / 2, 139947 / 4 * 3, 139947]).range(['#FFFFB2', '#FECC5C', '#FD8D3C', '#F03B20', '#BD0026']);
      centroid = d3.geo.centroid(kraje_geojson);
      projection = d3.geo.mercator().center(centroid).scale(2200).translate([135, 100]);
      geoPath = d3.geo.path().projection(projection);
      x$ = svg = rows.append("svg");
      x$.attr('class', 'map');
      y$ = svg.selectAll('path').data(function(it){
        return it.sumKraje.map(function(it){
          return {
            count: it.count,
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
        return escape(krajSum.kraj.nazev + ": <strong>" + formatNumber(krajSum.count) + "</strong> hospitalizací");
      });
      y$.attr('fill', function(){
        return color(getKrajValue.apply(this, arguments));
      });
      return y$;
    };
    formatNumber = function(num){
      num = num.toString();
      if (num.length > 3) {
        num = num.substr(0, num.length - 3) + "&nbsp;" + num.substr(-3);
      }
      return num;
    };
    return draw(getRowsBySkupiny());
  });
}).call(this);
