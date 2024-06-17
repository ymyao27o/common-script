
function configReplicaDeploy() {
    // 定义config变量：
    config = {
        _id: "configs", members: [
            { _id: 0, host: "sdb01:21000" },
            { _id: 1, host: "sdb02:21000" },
            { _id: 2, host: "sdb03:21000" }]
    }

    // 初始化副本集：
    rs.initiate(config)

    // 查看此时状态：
    print(simpleOutput(status))
}


function shardReplicaDeploy() {
    // 模式选择 P/S/S
    config = {
        _id: "shard1", members: [
            { _id: 0, host: "sdb01:27001" },
            { _id: 1, host: "sdb02:27001" },
            { _id: 2, host: "sdb03:27001" }
        ]
    }
    // 模式选择 P/S/A
    config = {
        _id: "shard1", members: [
            { _id: 0, host: "sdb01:27001" },
            { _id: 1, host: "sdb02:27001" },
            { _id: 2, host: "sdb03:27001", arbiterOnly: true }
        ]
    }
    rs.initiate(config);
    let status = rs.status()
    print(simpleOutput(status))
}


function mongosReplicaDeploy() {
    sh.addShard("shard1/sdb01:27001,sdb02:27001,sdb03:27001")
    // 查看集群状态：
    sh.status()
    sh.removeShard("shard2")
}


function simpleOutput(status) {
    let ret = []
    let members = status['members']

    members.forEach(ele => {
        ret.push({
            name: ele.name,
            health: ele.health,
            state: ele.state,
            stateStr: ele.stateStr,
        })
    });
    return ret
}

function createUser(){
    const host = 'mongodb://sdb01:27001/admin'
    let db = connect(host);
    db.createUser({user: "mongod",pwd: "mongod@1024",roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]})
}