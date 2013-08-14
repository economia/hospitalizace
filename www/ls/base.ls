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
            hosp: +row.HOSP
    cb err, data

(err, [hospitalizace]) <~ async.parallel [loadHospitalizace]
console.log hospitalizace

