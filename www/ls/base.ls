d3.selectAll ".fallback" .remove!
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
displayBySkupiny = ->
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

console.log displayBySkupiny!
