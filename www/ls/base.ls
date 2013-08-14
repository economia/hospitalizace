lineHeight = 200
linePadding = 20
barChartWidth = 200
numOfYears = 5
d3.selectAll ".fallback" .remove!
new Tooltip!watchElements!
loadHospitalizace = (cb) ->
    ssv = d3.dsv ";" "text/csv"
    (err, data) <~ ssv do
        "../hospitalizace.csv"
        (row) ->
            kod: row.KOD
            rok: row.ROK
            pohlavi: if row.POHL == "1" then "muz" else "zena"
            vek: row.VEKKAT
            kraj: +row.KRAJ
            pocetHospitalizovanych: +row.HOSP
            skupina: "#{row.KOD.substr 0 2}00"
    cb err, data

loadDiagnozy = (cb) ->
    (err, data) <~ d3.csv "../diagnozy.csv"
    cb err, data
loadSkupiny = (cb) ->
    (err, data) <~ d3.csv "../skupiny.csv"
    cb err, data
loadKraje = (cb) ->
    (err, data) <~ d3.csv "../kraje.csv"
    cb err, data
loadObyvatele = (cb) ->
    ssv = d3.dsv ";" "text/csv"
    (err, data) <~ ssv do
        "../obyv.csv"
        (row) ->
            rok: row.ROK
            pohlavi: if row.POHL == "1" then "muz" else "zena"
            vek: row.VEKKAT
            kraj: +row.KRAJ
            pocet: +row.OBYV
    cb err, data

loadGeoJsons = (cb) ->
    (err, data) <~ d3.json "../kraje.geojson"
    cb err, data

(err, [hospitalizace, diagnozy, skupiny, kraje_raw, kraje_geojson, obyvatele]) <~ async.parallel [loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadGeoJsons, loadObyvatele]
kraje = {}
for {id, nazev} in kraje_raw
    obyvateleAverage = 0
    kraje[id] = {nazev, obyvateleAverage}
for {geometry, id} in kraje_geojson.features
    kraje[id].geometry = geometry

recalculateKrajeObyv = ->
    for {rok, pohlavi, vek, kraj, pocet} in obyvatele
        kraje[kraj].obyvateleAverage += pocet / numOfYears

getRowsBySkupiny = ->
    currentHospitalizaceIndex = 0
    rows = skupiny.map (skupina) ->
        sum = 0
        sumYears =
            "2007": 0
            "2008": 0
            "2009": 0
            "2010": 0
            "2011": 0
        sumKraje = {}
        for id of kraje
            sumKraje[id] = 0
        loop
            row = hospitalizace[currentHospitalizaceIndex]
            if !row or row.skupina != skupina.kod
                break
            sum += row.pocetHospitalizovanych
            sumYears[row.rok] += row.pocetHospitalizovanych
            sumKraje[row.kraj] += row.pocetHospitalizovanych
            currentHospitalizaceIndex++
        sumYearsArray = for index, count of sumYears
            year: index, count: count
        sumKrajeArray = for index, count of sumKraje
            kraj: kraje[index], count: count
        return do
            title: skupina.nazev
            sum: sum
            sumYears: sumYearsArray
            sumKraje: sumKrajeArray
draw = (rowsData) ->
    rowsData.sort (a, b) -> b.sum - a.sum
    sums = rowsData.map (.sum)
    container = d3.select ".container"
    rows = container
        .selectAll ".row"
        .data rowsData
        .enter!.append "div"
            .attr \class \row
    rows
        .append "h2"
            ..text (row, index) -> "#{index+1}. #{row.title}"

    drawSums sums, rows
    drawBarCharts rows, rowsData
    drawMap rows, rowsData


drawSums = (sumValues, rows) ->
    scale = d3.scale.sqrt!
        .domain [0 sumValues[0]]
        .range [1 5]
    heightScale = d3.scale.sqrt!
        .domain [0 sumValues[0]]
        .range [30 110]
    rows.append "div"
        ..attr \class \sum
        ..attr \data-tooltip -> escape "Průměrně <strong>#{formatNumber Math.round it.sum / 5}</strong> hospitalizací ročně"
        ..append \div
            ..attr \class \valueContainer
            ..append "span"
                ..attr \class \value
                ..text ->
                    if it.sum > 1000
                        "#{Math.round it.sum / 5000}"
                    else
                        "méně než"
                ..style \font-size -> "#{scale it.sum}em"
            ..append \span
                ..html "<br />tisíc hospitalizací"
            ..style \height -> "#{heightScale it.sum}px"

drawBarCharts = (rows, rowsData) ->
    maxValue = -Infinity
    for row in rowsData
        for {count} in row.sumYears
            if count > maxValue then maxValue = count

    scale = d3.scale.linear!
        ..domain [0 maxValue]
        ..range [1 lineHeight - 3*linePadding]
    columnWidth = barChartWidth / numOfYears
    rows.append "div"
        .attr \class \years
        .style \bottom (data) ->
            values = data.sumYears.map (.count)
            max = scale Math.max ...values
            bottom = ((lineHeight - 2*linePadding) - max) / 2
            "#{bottom}px"
        .selectAll ".year"
        .data -> it.sumYears
        .enter!
        .append \div
            ..attr \class \year
            ..attr \data-tooltip (data) -> escape "<strong>#{formatNumber data.count}</strong> hospitalizací"
            ..style \width "#{columnWidth-1}px"
            ..style \left (data, index) -> "#{index*columnWidth}px"
            ..append \div
                ..attr \class \value
                ..style \height (yearData, yearIndex, rowIndex) ->
                    "#{scale yearData.count}px"
                ..append \div
                    ..attr \class \popis
                    ..text -> it.year
drawMap = (rows, rowsData) ->
    tstMax = -Infinity
    getKrajValue = (item, krajIndex, rowIndex) ->
        data = rowsData[rowIndex]
        krajSum = data.sumKraje[krajIndex]
        return 0 if not krajSum.kraj.obyvateleAverage
        value = (krajSum?.count || 0) / (krajSum.kraj.obyvateleAverage || 1)
        if value > tstMax
            tstMax := value
        value
    color = d3.scale.linear!
        .domain [0 0.189/4 0.189/2 0.189/4*3 0.189]
        .range <[#FFFFB2 #FECC5C #FD8D3C #F03B20 #BD0026]>

    centroid = d3.geo.centroid kraje_geojson
    projection = d3.geo.mercator!
        .center centroid
        .scale 2000
        .translate [135 100]
    geoPath = d3.geo.path!.projection projection
    svg = rows.append "svg"
        ..attr \class \map
    svg.selectAll \path
        .data ->
            it.sumKraje.map ->
                count: it.count
                obyvateleAverage: it.kraj.obyvateleAverage
                geometry: it.kraj.geometry
                title: it.kraj.nazev
                type: \Feature
        .enter!.append \path
            ..attr \d geoPath
            ..attr \data-tooltip (item, krajIndex, rowIndex) ->
                data = rowsData[rowIndex]
                data = rowsData[rowIndex]
                krajSum = data.sumKraje[krajIndex]
                escape "#{krajSum.kraj.nazev}: <strong>#{formatNumber Math.round krajSum.count / krajSum.kraj.obyvateleAverage * 100_000}</strong> hospitalizací na&nbsp;sto tisíc obyvatel"
            ..attr \fill ->
                color getKrajValue ...

formatNumber = (num) ->
    num .= toString!
    if num.length > 3
        num = "#{num.substr 0, num.length - 3}&nbsp;#{num.substr -3}"
    num

recalculateKrajeObyv!
draw getRowsBySkupiny!
