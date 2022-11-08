//=====================  모듈  =====================//
// Express 기본 모듈 불러오기
var express = require('express')
  , http = require('http')
  , path = require('path');

// 익스프레스의 미들웨어 불러오기
var bodyParser = require('body-parser')
  , static = require('serve-static')
  , cookieParser = require('cookie-parser')

// 세션 모듈 불러오기
var expressSession = require('express-session');


// 몽고디비 모듈 사용
var MongoClient = require('mongodb').MongoClient;

// mongoose 모듈 불러들이기
var mongoose = require('mongoose');

// crypto 모듈 불러들이기
var crypto = require('crypto');


//=====================  데이터베이스  =====================//

// 데이터베이스 객체를 위한 변수 선언
var database;

// 데이터베이스 스키마 객체를 위한 변수 선언
var UserSchema;

// 데이터베이스 모델 객체를 위한 변수 선언
var UserModel;


// 데이터베이스에 연결
function connectDB(){
  // 데이터베이스 연결 정보
  var databaseUrl = 'mongodb://210.125.31.240:27017/HUG';
  
  // 데이터 베이스 연결
  console.log('데이터베이스 연결을 시도합니다.');
  mongoose.Promise = global.Promise;
  mongoose.connect(databaseUrl);
  database = mongoose.connection;
  
  database.on('error', console.error.bind(console, 'mongoose connection error.'));
  database.on('open', function (){
      console.log('데이터베이스에 연결되었습니다. : ' + databaseUrl);
      
      createUserSchema();
      createHugSchema();
      createContractSchema();
  });
  
  // 연결 끊어졌을 때 5초 후 재연결
  database.on('disconnected', function(){
      console.log('연결이 끊어졌습니다. 5초 후 다시 연결합니다.');
      setInterval(connectDB, 5000);
  });
}


// user 스키마 및 모델 객체 생성
function createUserSchema(){
  // 스키마 정의
  // password를 hased_password로 변경, default 속성 모두 추가, salt 속성 추가
  UserSchema = mongoose.Schema({
          id: {type: String, required: true, unique: true, 'default' : ' '},
          hashed_password : {type: String, required: true, 'default' : ' '},
          salt : {type: String, required: true},
          name: {type: String, index: 'hashed', 'default': ' '},
          auth: {type: Number, 'default': 0},
          hug_num : {type: Number, 'default': 0},
          contract_account: {type: String, required: true, unique: true, 'default' : ' '}
      }, {
          versionKey: false   // 버전 키가 자동으로 추가되기 때문에 없애고 싶으면 해당 필드 추가 필요
  });

  // password를 virtual 메소드로 정의 : MongoDB에 저장되지 않는 편리한 속성임. 특정 속성을 지정하고 set, get 메소드를 정의함
  UserSchema
      .virtual('password')
      .set(function(password){
          this._password = password;
          this.salt = this.makeSalt();
          this.hashed_password = this.encryptPassword(password);
          console.log('virtual password 호출됨 : ' + this.hashed_password);
      })
      .get(function() {return this._password});

  // 스키마에 모델 인스턴스에서 사용할 수 있는 메소드 추가
  // 비밀번호 암호화 메소드
  UserSchema.method('encryptPassword', function(plainText, inSalt){
     if(inSalt){
         return crypto.createHmac('sha1', inSalt).update(plainText).digest('hex');
     } else {
         return crypto.createHmac('sha1', this.salt).update(plainText).digest('hex');
     }
  });
  
  // salt 값 만들기 메소드
  UserSchema.method('makeSalt', function(){
      return Math.round((new Date().valueOf() * Math.random())) + '';
  });
  
  UserSchema.method('authenticate', function(plainText, inSalt, hashed_password){
      if(inSalt){
          console.log('authenticate 호출됨 : %s -> %s : %s', plainText, this.encryptPassword(plainText, inSalt), hashed_password);
          return this.encryptPassword(plainText, inSalt) == hashed_password;
      } else {
          console.log('authenticate 호출됨 : %s -> %s : %s', plainText, this.encryptPassword(plainText), this.hashed_password);
          return this.encryptPassword(plainText) == this.hashed_password;
      }
  });
  
  // 필수 속성에 대한 유효성 확인(길이 값 체크)
  UserSchema.path('id').validate(function(id){
      return id.length;
  }, 'id 칼럼의 값이 없습니다.');
  
  UserSchema.path('name').validate(function(name){
      return name.length;
  }, 'name 칼럼의 값이 없습니다.');

  UserSchema.path('contract_account').validate(function(contract_account){
    return contract_account.length;
}, 'contract_account 칼럼의 값이 없습니다.');
  
  
  // 스키마에 static 메소드 추가
  UserSchema.static('findById', function(id, callback){
     return this.find({id: id}, callback); 
  });

  UserSchema.static('findAll', function(callback){
      return this.find({ }, callback);
  });
      
  
  console.log('UserSchema 정의함.')

  // UserModel 모델 정의
  UserModel = mongoose.model("member", UserSchema);
  console.log('UserModel 정의함.');
}



// hug 스키마 및 모델 객체 생성
function createHugSchema(){
    // 스키마 정의
    HugSchema = mongoose.Schema({
            id: {type: String, unique: true, 'default' : ' '},
            contents : {type: String, 'default' : ' '},
            deadline : {type: Date, 'default': ' '},
            goal_num: {type: Number, 'default': 0},
            join_fee: {type: Number, 'default': 0},
            open_fee : {type: Number, 'default': 0},
            member: {type: Array, 'default' : []}
        }, {
            versionKey: false   // 버전 키가 자동으로 추가되기 때문에 없애고 싶으면 해당 필드 추가 필요
    });
  
    // 스키마에 static 메소드 추가
    HugSchema.static('findById', function(id, callback){
       return this.find({id: id}, callback); 
    });
  
    HugSchema.static('findAll', function(callback){
        return this.find({ }, callback);
    });
        
    
    console.log('HugSchema 정의함.')
  
    // HugModel 모델 정의
    HugModel = mongoose.model("hug", HugSchema);
    console.log('HugModel 정의함.');
  }
  

// Contracts 스키마 및 모델 객체 생성
function createContractSchema(){
    // 스키마 정의
    ContractSchema = mongoose.Schema({
            address: {type: String, unique: true, 'default' : ' '},
            HUG : {type: Array, 'default': []}
        }, {
            versionKey: false   // 버전 키가 자동으로 추가되기 때문에 없애고 싶으면 해당 필드 추가 필요
    });
  
    // 스키마에 static 메소드 추가
    HugSchema.static('findById', function(addr, callback){
       return this.find({address: addr}, callback); 
    });
  
    HugSchema.static('findAll', function(callback){
        return this.find({ }, callback);
    });
        
    
    console.log('ContractSchema 정의함.')
  
    // HugModel 모델 정의
    ContractModel = mongoose.model("contract", ContractSchema);
    console.log('ContractModel 정의함.');
  }
  





//=====================  사용자 로그인 및 회원가입 관리  =====================//

// 사용자를 인증하는 함수 : 아이디로 먼저 찾고 비밀번호를 그 다음에 비교
var authUser = function(database, id, password, callback){
  console.log('authUser 호출됨 : ' + id + ', ' + password);
  
      
  // 1. 아이디를 사용해 검색
  UserModel.findById(id, function(err, results){
      if(err){
          callback(err, null);
          return;
      }

      console.log('아이디 [%s]로 사용자 검색 결과', id);
      console.dir(results);


      if (results.length > 0){
          console.log('아이디와 일치하는 사용자 찾음.');
          
          // 2. 비밀번호 확인
          var user = new UserModel({id : id});
          var authenticated = user.authenticate(password, results[0]._doc.salt, results[0]._doc.hashed_password);
          
          if(authenticated){
              console.log('비밀번호 일치함.');
              callback(null, results);
          } else {
              console.log('비밀번호 일치하지 않음.');
              callback(null, null);
          }
      } else {
          console.log('아이디와 일치하는 사용자를 찾지 못함.');
          callback(null, null);
      }
  });
}


// 사용자를 추가하는 함수
var addUser = function(database, id, password, name, contract_account, callback) {
  console.log('addUser 호출됨 : ' + id + ', ' + password + ', ' + name + ', ' + contract_account);


  // UserModel의 인스턴스 생성
  var user = new UserModel({"id": id, "password": password, "name": name, "contract_account": contract_account});
  
  user.save(function(err){
      if (err) {
          // 오류가 발생했을 때 콜백 함수를 호출하면서 오류 객체 전달
          callback(err, null);
          return;
      }
      
      console.log('사용자 데이터 추가함.');
      callback(null, user);
  });
}

//=====================  HUG - Create 페이지 처리  =====================//

var addHug = function(database, pcontents, pdeadline, pgoalNum, pjoinFee, popenFee, puserId, callback) {
    console.log('addHug 호출됨');
    
    // id로 검색해서 hug num 받아오기
    UserModel.findById(puserId, function(err, results){
        if(err){
            callback(err, null);
            return;
        }
  
        if (results.length > 0){
            console.log('아이디와 일치하는 사용자 찾음.');

            var num = results[0]._doc.hug_num + 1;
            UserModel.updateOne(
                {id : puserId},
                {hug_num: num}, function(err){
                    if (err) {
                        // 오류가 발생했을 때 콜백 함수를 호출하면서 오류 객체 전달
                        callback(err, null);
                        return;
                    }
            
                    console.log('HUG num 수정.');
                }
            );
            // HugModel의 인스턴스 생성
            var hug = new HugModel({"id": puserId + ';' + num,
                "contents": pcontents,
                "deadline": pdeadline,
                "goal_num": pgoalNum,
                "join_fee": pjoinFee,
                "open_fee": popenFee
            });
            
            hug.save(function(err){
                if (err) {
                    // 오류가 발생했을 때 콜백 함수를 호출하면서 오류 객체 전달
                    callback(err, null);
                    return;
                }
        
                console.log('HUG 데이터 추가함.');
                callback(null, hug);
            });
            
        } else {
            console.log('아이디와 일치하는 사용자를 찾지 못함.');
            callback(null, null);
        }
    });
  }



//=====================  익스프레스  =====================//

var app = express();

// 기본 속성 설정
app.set('port', process.env.PORT || 8080);

// body-parser를 사용해 application/x-www-form-urlencoded 파싱 (bodyParser.json()은 json 형식으로 전달된 요청 파라미터를 파싱)
app.use(bodyParser.urlencoded({extended: false}));

// body-parser를 사용해 application/json 파싱
app.use(bodyParser.json());

// 쿠키 파서 등록
app.use(cookieParser());

// 세션 설정
app.use(expressSession({
    secret: 'my key',
    resave: true,
    saveUninitialized: true
}));

app.use(express.static('src'));
app.use(express.static('../hug-contract/build/contracts'));
app.engine('html', require('ejs').renderFile);
app.set('view engine', 'html');
app.set('views', path.join(__dirname, '/src'));

// main
app.get('/', function (req, res) {
    res.render('index.html');
});

// move to login
app.get('/login', function (req, res){
        res.render('login.html');
});

// move to join
app.get('/join', function (req, res){
        res.render('join.html');
});

// move to create
app.get('/create', function (req, res){
  res.render('create.html');
});

// move to search
app.get('/search', function (req, res){
  res.render('search.html');
});


//=====================  라우터  =====================//

// 라우터 사용하여 라우팅 함수 등록
var router = express.Router();

// 로그인 함수
router.route('/process/login').post(function(req, res){
  console.log('/process/login 호출됨.');
  
  var paramId = req.body.id || req.query.id;
  var paramPassword = req.body.pw || req.query.pw;
  userid = paramId;
 
    if (database) {
        authUser(database, paramId, paramPassword, function(err, docs){
            if(err) {throw error;}
    
            if(docs) {
                console.dir(docs);
                var username = docs[0].name;

                // 세션 저장
                req.session.user = {
                    id: paramId,
                    name: username,
                    authorized: true
                };

                res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
                res.write('<h1>로그인 성공</h1>');
                res.write('<div><p>사용자 아이디 :</p></div><div><p id = now_id>' +paramId+ '</p></div>');
                res.write('<div><p>사용자 이름 : </p></div><div><p id = now_name>' +username+ '</p></div>');
                res.write("<br><br><a href= '/index.html'>메인으로 돌아가기</a>");
                res.write("<script>sessionStorage.setItem('num',"+ docs[0].hug_num +");</script>");
                res.write("<script>var id = document.getElementById('now_id').innerText;console.log(id);sessionStorage.setItem('id', id);</script>");
                res.write("<script>var name = document.getElementById('now_name').innerText;console.log(id);sessionStorage.setItem('name', name);</script>");
                res.end();
                
            } else {
                res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
                res.write('<h1>로그인 실패</h1>');
                res.write('<div><p>아이디와 비밀번호를 다시 확인하십시오.</p></div>');
                res.write("<br><br><a href= '/login.html'>다시 로그인하기</a>");
                res.end();
            }
        });
    } else {
        res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
        res.write('<h2>데이터베이스 연결 실패</h2>');
        res.write('<div><p>데이터베이스에 연결하지 못했습니다.</p></div>');
        res.end();
    }
});

// 사용자 추가 라우팅 함수 - 클라이언트에서 보내온 데이터를 이용해 데이터베이스에 추가
router.route('/process/adduser').post(function(req, res){
  console.log('/process/adduser 호출됨.');
  var paramId = req.body.id || req.query.id;
  var paramPassword = req.body.pw || req.query.pw;
  var paramName = req.body.name || req.query.name;
  var paramContractAccount = req.body.account_addr || req.query.account_addr;
  
  console.log('요청 파라미터 : ' + paramId + ', ' + paramPassword + ', ' + paramName, ', ' + paramContractAccount);
  
  // 데이터베이스 객체가 초기화된 경우, addUser 함수 호출하여 사용자 추가
  if (database){
      addUser(database, paramId, paramPassword, paramName, paramContractAccount, function(err, result){
          if(err){throw err;}
          
          // 결과 객체 확인하여 추가된 데이터 있으면 성공 응답 전송
          if(result){
              console.dir(result);
              res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
              res.write('<h2>회원 가입이 완료되었습니다.</h2>');
              res.write("<br><br><a href= '/index.html'>메인 화면으로 돌아가기</a>");
              res.end();
          } else {
              // 결과 객체가 없으면 실패 응답 전송
              res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
              res.write('<h2>회원 가입에 실패하셨습니다.</h2>');
              res.write("<br><br><a href= '/index.html'>메인 화면으로 돌아가기</a>");
              res.end();
          }
      });
  }else {
      // 데이터베이스 객체가 초기화되지 않은 경우 실패 응답 전송
      res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
      res.write('<h2>데이터베이스 연결 실패</h2>');
      res.end();
  }
});

// 로그아웃 라우팅 함수 - 로그아웃 후 세션 삭제함
router.route('/process/logout').get(function(req, res){
    console.log('/process/logout 호출됨.');
    
    if(req.session.user){
        // 로그인된 상태
        console.log('로그아웃합니다.');
        
        req.session.destroy(function(err){
            if(err){throw err;}
            
            console.log('세션을 삭제하고 로그아웃되었습니다.');
            res.redirect('/index.html');
        });
    } else {
        // 로그인 안된 상태
        console.log('아직 로그인되어 있지 않습니다.');
        res.redirect('/index.html');
    }
});


// HUG - create 데이터베이스에 추가 및 처리
router.route('/hug/create').post(function(req, res){
    console.log('/hug/create 호출됨.');
    var ptitle = req.body.title || req.query.title;
    var pgoalDate = req.body.goal_date || req.query.goal_date;
    var pcontent = req.body.content || req.query.content;
    var pdeadline = req.body.deadline || req.query.deadline;
    var pgoalNum = req.body.goal_num || req.query.goal_num;
    var pjoinFee = req.body.join_fee || req.query.join_fee;
    var popenFee = req.body.open_fee || req.query.open_fee;
    var puserId = req.body.user_id || req.query.user_id;
    var ca = req.body.ca || req.query.ca;

    

    var pcontents = ptitle + ';' + pgoalDate + ';' + pcontent;
    
    // 데이터베이스 객체가 초기화된 경우, addHug 함수 호출하여 추가
    if (database){
        addHug(database, pcontents, new Date(pdeadline), pgoalNum, pjoinFee, popenFee, puserId, function(err, result){
            if(err){throw err;}
            // 결과 객체 확인하여 추가된 데이터 있으면 성공 응답 전송
            if(result){
                ContractModel.updateOne(
                    {address : ca},
                    {$push : {HUG: result._id}}, function(err){
                        if (err) {
                            // 오류가 발생했을 때 콜백 함수를 호출하면서 오류 객체 전달
                            callback(err, null);
                            return;
                        }
                
                        console.log('HUG 추가.');
                    }
                );

                res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
                res.write("<script>alert('성공 했습니다.');location.href='/';</script>");
                res.end();
            } else {
                // 결과 객체가 없으면 실패 응답 전송
                res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
                res.write("<script>alert('실패 했습니다. 다시 시도하세요.');location.href='/create';</script>");
                res.end();
            }
        });
    }else {
        // 데이터베이스 객체가 초기화되지 않은 경우 실패 응답 전송
        res.writeHead('200', {'Content-Type':'text/html;charset=utf8'});
        res.write('<h2>데이터베이스 연결 실패</h2>');
        res.end();
    }
});

// 라우터 객체를 app 객체에 등록
app.use('/', router);



//=====================  오류  =====================//

// Express 서버 시작
http.createServer(app).listen(app.get('port'), function(){
  console.log('서버가 시작되었습니다. 포트 : ' + app.get('port'));
  
  // 데이터베이스 연결
  connectDB();

});




