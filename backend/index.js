const { query } = require('express')
const express = require('express')
const app = express()
const cors = require('cors')
const port = 8080
const db = require('better-sqlite3')('esp32.db')
db.pragma('journal_mode = WAL');
const env = require('dotenv').config()
app.use(cors())
try {
    db.exec("create table esp32(ipaddress text primary key, timestamp text, cor text, modo text, waittime integer)");
    db.exec("create table zigbee_preserve_status(ieee text primary key, name text)")
} catch (err) {
    if(!err.toString().indexOf("already exists") > 0){
        throw err
    }
}
let isRegistering = false;
app.put('/registar', function (req,res){
    isRegistering = true
    if(!req.query.ip){
        res.status(400).send("falta o ?ip=xxxxx")
        return
    }
    let sql = 'select * from esp32 where ipaddress = ?'
    let row = db.prepare(sql).get(req.query.ip)
    console.log(row)
    let data = {
        ipaddress: req.query.ip,
        timestamp: (new Date()).getTime(),
        cor: req.query.cor,
        waittime: req.query.waitTime,
        modo: req.query.modo
    }
    if(!row){
        //nao existe, vou criar
        try {
            let novo = db.prepare('insert into esp32(ipaddress, timestamp, cor, modo, waittime) values (@ipaddress, @timestamp, @cor, @modo, @waittime)').run(data)
            console.log(novo)
            res.status(200).send('top')
        } catch (error) {
            console.log(error)
            res.status(400).send("erro")
        }
        isRegistering = false
        return
    }
    
    let result = db.prepare('update esp32 set timestamp = @timestamp, cor = @cor, waittime = @waittime, modo = @modo where ipaddress = @ipaddress').run(data)
    console.log(result)
    isRegistering = false
    res.status(200).send("top")
})

app.get('/getall', function(req,res){
    let sql = 'select * from esp32'
    let rows = db.prepare(sql).all()
    res.json({dados:rows})
})

app.post('/guardarestado', function (req,res){
    if(!req.body.ieee) {
        res.status(400).send({err:"body nao tem ieee address"})
        return
    }
    if(!req.body.name) {
        res.status(400).send({err:"body nao tem name address"})
        return
    }
    let sql = 'select * from zigbee_preserve_status where ieee = ?'
    let row = db.prepare(sql).get(req.body.ieee)
    let data = {
        ieee: req.body.ieee,
        name: req.body.name
    }
    if(!row){
        //nao existe, vou criar
        try {
            let novo = db.prepare('insert into zigbee_preserve_status(ieee, name) values (@ieee, @name)').run(data)
            console.log(novo)
            res.status(200).send('top')
        } catch (error) {
            console.log(error)
            res.status(400).send("erro a inserir")
        }
        return
    }
    res.status(300).send({err:"already saved state"})
})

app.post('/naoguardarestado', function (req,res){
    if(!req.body.ieee) {
        res.status(400).send({err:"body nao tem ieee address"})
        return
    }
    if(!req.body.name) {
        res.status(400).send({err:"body nao tem name address"})
        return
    }
    let sql = 'select * from zigbee_preserve_status where ieee = ?'
    let row = db.prepare(sql).get(req.body.ieee)
    let data = {
        ieee: req.body.ieee,
        name: req.body.name
    }
    if(row){
        //existe, vou apagar
        try {
            let novo = db.prepare('delete from zigbee_preserve_status where ieee = @ieee').run(data)
            console.log(novo)
            res.status(200).send('top')
        } catch (error) {
            console.log(error)
            res.status(400).send("erro a inserir")
        }
        return
    }
    res.status(400).send({err:"doesnt exist"})
})

setInterval(function(){
    if(isRegistering) return
    let sql = 'select * from esp32'
    let row = db.prepare(sql).all()
    let coisosARemover = []
    let remover = db.prepare('delete from esp32 where ipaddress = ?')
    if(row){
        let data = new Date()
        for (const esp of row) {
            if((data.getTime() - (new Date(parseInt(esp.timestamp))).getTime())/60/1000 >= 10){
                coisosARemover.push({ipaddress:esp.ipaddress})
            }
        }
    }
    let removertodos = db.transaction((linhas)=>{
        for(const i of linhas) remover.run(i.ipaddress)
    })
    removertodos(coisosARemover)
},process.env.LOOP_SECONDS)

app.listen(port, () => {
    console.log("running");
})