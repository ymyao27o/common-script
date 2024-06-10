
// 通过连接地址创建数据库company
const host = 'mongodb://127.0.0.1:27017/company'

// 集合预备数据
const employee = [
    { "name": "Alice", "department": "engineering", "age": 34 },
    { "name": "Bob", "department": "sales", "age": 25 },
    { "name": "Carol", "department": "finance", "age": 31 }
];

// 通过地址创建连接
let db = connect(host);

// 插入集合数据
db.employees.insertMany(employee);

// 查询验证插入
const document = db.employees.find().pretty();

// 输出结果
printjson(document);