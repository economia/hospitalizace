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

(err, [hospitalizace, diagnozy, skupiny, kraje_raw]) <~ async.parallel [loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje]
kraje = {}
for {id, nazev} in kraje_raw
    kraje[id] = {nazev}
getRowsBySkupiny = ->
    currentHospitalizaceIndex = 0
    rows = skupiny.map (skupina) ->
        sum = 0
        sumYears = {}
        sumKraje = {}
        loop
            row = hospitalizace[currentHospitalizaceIndex]
            if !row or row.skupina != skupina.kod
                break
            sum += row.pocetHospitalizovanych
            sumYears[row.rok] ?= 0
            sumYears[row.rok] += row.pocetHospitalizovanych
            sumKraje[row.kraj] ?= 0
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


drawSums = (sumValues, rows) ->
    scale = d3.scale.sqrt!
        .domain [0 sumValues[0]]
        .range [0 lineHeight - 2*linePadding]
    rows.append "div"
        ..attr \class \sum
        ..append "div"
            ..attr \class \value
            ..style \width -> "#{scale it.sum}px"
            ..style \height -> "#{scale it.sum}px"

drawBarCharts = (rows, rowsData) ->
    maxValue = -Infinity
    for row in rowsData
        for {count} in row.sumYears
            if count > maxValue then maxValue = count

    scale = d3.scale.linear!
        ..domain [0 maxValue]
        ..range [0 lineHeight - linePadding]
    columnWidth = barChartWidth / numOfYears
    rows.append "div"
        .attr \class \years
        .selectAll ".year"
        .data -> it.sumYears
        .enter!
        .append \div
            ..attr \class \year
            ..attr \data-tooltip (data) -> "#{formatNumber data.count} hospitalizací"
            ..style \width "#{columnWidth}px"
            ..style \left (data, index) -> "#{index*columnWidth}px"
            ..style \height (yearData, yearIndex, rowIndex) ->
                "#{scale yearData.count}px"
formatNumber = (num) ->
    num .= toString!
    if num.length > 3
        num = "#{num.substr 0, num.length - 3} #{num.substr -3}"
    num

draw getRowsBySkupiny!
