lineHeight = 200
linePadding = 20
barChartWidth = 170
numOfYears = 5
d3.selectAll ".fallback" .remove!
d3.selectAll ".hiddenIfIncapableBrowser" .attr "class" ""
skupinyWithoutDetails = []
new Tooltip!watchElements!
loadHospitalizace = (cb) ->
    ssv = d3.dsv ";" "text/csv"
    (err, data) <~ ssv do
        "../hospitalizace.csv"
        (row) ->
            skupina = "#{row.KOD.substr 0 2}00"
            if row.KOD == skupina and skupina not in skupinyWithoutDetails
                skupinyWithoutDetails.push skupina
            return do
                kod: row.KOD
                rok: row.ROK
                pohlavi: if row.POHL == "1" then "muz" else "zena"
                vek: row.VEKKAT
                kraj: +row.KRAJ
                pocetHospitalizovanych: +row.HOSP
                skupina: skupina
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

(err, [hospitalizace, diagnozy_raw, skupiny, kraje_raw, kraje_geojson, obyvatele]) <~ async.parallel [loadHospitalizace, loadDiagnozy, loadSkupiny, loadKraje, loadGeoJsons, loadObyvatele]
kraje = {}
for {id, nazev} in kraje_raw
    obyvateleAverage = 0
    kraje[id] = {nazev, obyvateleAverage}
for {geometry, id} in kraje_geojson.features
    kraje[id].geometry = geometry
diagnozy = {}
for {kod, nazev} in diagnozy_raw
    diagnozy[kod] = nazev
for record in hospitalizace
    record.nazev = diagnozy[record.kod]


recalculateKrajeObyv = ->
    for krajId, kraj of kraje
        kraj.obyvateleAverage = 0
    for {rok, pohlavi, vek, kraj, pocet}:record in obyvatele
        if passingFilter record
            kraje[kraj].obyvateleAverage += pocet / numOfYears
lastDisplayedRows = null
getRows = (skupinaId) ->
    if skupinaId is void
        skupinaId = lastDisplayedRows
    lastDisplayedRows := skupinaId
    checkBackButton!
    currentHospitalizaceIndex = 0
    rows = if not skupinaId
        skupiny
    else
        kodyPresent = {}
        hospitalizace.filter ->
            if !kodyPresent[it.kod] and it.skupina == skupinaId
                kodyPresent[it.kod] = yes
                yes
            else
                no

    rows.map (record) ->
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
        foundSomething = no
        loop
            row = hospitalizace[currentHospitalizaceIndex]
            break if !row
            isValidRow = if not skupinaId
                row.skupina == record.kod
            else
                row.kod == record.kod
            if not isValidRow
                if foundSomething
                    break
                else
                    currentHospitalizaceIndex++
                    continue
            foundSomething = yes
            currentHospitalizaceIndex++
            continue if not passingFilter row
            sum += row.pocetHospitalizovanych
            sumYears[row.rok] += row.pocetHospitalizovanych
            sumKraje[row.kraj] += row.pocetHospitalizovanych
        sumYearsArray = for index, count of sumYears
            year: index, count: count
        sumKrajeArray = for index, count of sumKraje
            kraj: kraje[index], count: count
        mappedData =
            title: record.nazev
            sum: sum
            sumYears: sumYearsArray
            sumKraje: sumKrajeArray
        if not skupinaId
            mappedData.skupinaId = record.kod
        mappedData
passingFilter = (record) ->
    if filters.pohlavi and record.pohlavi isnt filters.pohlavi
        return false
    if filters.vek and record.vek isnt filters.vek
        return false
    return true
draw = (rowsData) ->
    rowsData.sort (a, b) -> b.sum - a.sum
    sums = rowsData.map (.sum)
    container = d3.select ".container"
    container.selectAll "*" .remove!
    rows = container
        .selectAll ".row"
        .data rowsData
        .enter!.append "div"
            .attr \class \row
    h2 = rows.append "h2"
        ..html (row, index) -> "#{index+1}. <span>#{row.title}</span>"
    if not lastDisplayedRows
        h2
            .filter (row) -> row.skupinaId not in skupinyWithoutDetails
            .html (row, index) -> "#{index+1}. <span>#{row.title} &raquo;</span>"
            .attr \class \link
            .attr \data-tooltip "Kliknutím zobrazíte jednotlivé diagnózy"
            .on \click (row) ->
                $selectSkupina
                    ..val row.skupinaId
                    ..trigger "chosen:updated"
                draw getRows row.skupinaId

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
                ..style \font-size ->
                    height = scale it.sum
                    if it.sum <= 1000
                        height = Math.min height, 1.75
                    "#{height}em"
            ..append \span
                ..html "<br />tisíc hospitalizací"
            ..style \height ->
                height = heightScale it.sum
                if it.sum <= 1000
                    height = Math.min height, 45
                "#{height}px"

drawBarCharts = (rows, rowsData) ->
    maxValue = -Infinity
    for row in rowsData
        for {count} in row.sumYears
            if count > maxValue then maxValue = count

    scale = d3.scale.linear!
        ..domain [0 maxValue]
        ..range [1 lineHeight - 3*linePadding]
    maxHeight = scale.range.1
    columnWidth = barChartWidth / numOfYears
    rows.append "div"
        .attr \class \years
        .each (data) ->
            values = data.sumYears.map (.count)
            max = scale Math.max ...values
            bottom = ((lineHeight - 2*linePadding) - max) / 2
            data._bottom = bottom
        .style \top (data) -> "#{data._bottom}px"
        .style \height (data) -> "#{lineHeight - 2*data._bottom}px"
        .selectAll ".year"
        .data -> it.sumYears
        .enter!
        .append \div
            ..attr \class \year
            ..attr \data-tooltip (data) -> escape "<strong>#{formatNumber data.count}</strong> hospitalizací"
            ..style \width "#{columnWidth-2}px"
            ..style \left (data, index) -> "#{index*columnWidth}px"
            ..append \div
                ..attr \class \value
                ..style \height (yearData, yearIndex, rowIndex) ->
                    "#{scale yearData.count}px"
                ..append \div
                    ..attr \class \popis
                    ..text -> it.year
drawMap = (rows, rowsData) ->
    mapMaxValue = -Infinity
    for {sumKraje} in rowsData
        for {count, kraj} in sumKraje
            value = count / kraj.obyvateleAverage
            if value > mapMaxValue
                mapMaxValue = value
    if mapMaxValue == 0 then mapMaxValue = 1 # fix when no hospitalizations are recorded in category

    getKrajValue = (item, krajIndex, rowIndex) ->
        data = rowsData[rowIndex]
        krajSum = data.sumKraje[krajIndex]
        return 0 if not krajSum.kraj.obyvateleAverage
        value = (krajSum?.count || 0) / krajSum.kraj.obyvateleAverage
        value
    color = d3.scale.linear!
        .domain [0 mapMaxValue/4 mapMaxValue/2 mapMaxValue/4*3 mapMaxValue]
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

$selectSkupina = $ "<select data-placeholder='Všechny druhy nemocí' ><option value=''></option></select>"
    ..appendTo ".selectionRow .skupina"
$selectSkupina = $ ".selectionRow .skupina select"
    ..on \change ->
        draw getRows @value
for skupina in skupiny
    if skupina.kod not in skupinyWithoutDetails
        $ "<option value='#{skupina.kod}'>#{skupina.nazev}</option>"
            ..appendTo $selectSkupina
$selectSkupina
    ..chosen allow_single_deselect: true

$selectPohlavi = $ "<select data-placeholder='Obě pohlaví'>
<option value=''></option>
<option value='muz'>Muži</option>
<option value='zena'>Ženy</option>
</select>"
    ..appendTo ".selectionRow .pohlavi"
$selectPohlavi = $ ".selectionRow .pohlavi select"
    ..on \change ->
        changeFilter "pohlavi" @value
    ..chosen allow_single_deselect: true

$selectVek = $ "<select data-placeholder='Všechny věkové kategorie'>
<option value=''></option>
<option value='15-34'>15-34</option>
<option value='35-44'>35-44</option>
<option value='45-54'>45-54</option>
<option value='55-64'>55-64</option>
<option value='65-74'>65-74</option>
<option value='75+'>75+</option>
</select>"
    ..appendTo ".selectionRow .vek"
$selectVek = $ ".selectionRow .vek select"
    ..on \change -> changeFilter \vek @value
    ..chosen allow_single_deselect: true

filters = {}
changeFilter = (field, value) ->
    if value.length is 0 then value = false
    filters[field] = value
    checkBackButton!
    recalculateKrajeObyv!
    draw getRows void
$ ".selectionRow .back a" .click (evt) ->
    evt.preventDefault!
    filters := {}
    recalculateKrajeObyv!
    draw getRows null
    $selectSkupina
        ..val ""
        ..trigger "chosen:updated"
checkBackButton = ->
    if filters.vek || filters.pohlavi || lastDisplayedRows
        $ ".selectionRow .back" .removeClass "disabled"
    else
        $ ".selectionRow .back" .addClass "disabled"

recalculateKrajeObyv!
draw getRows null
