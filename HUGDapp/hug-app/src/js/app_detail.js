App = {
  web3Provider: null,
  contracts: {},
  names: new Array(),
  url: 'http://127.0.0.1:8545',

  // web3 개체를 가진 앱 시작
  init: function() {
    return App.initWeb3();
  },

  // web3 프로파이더와 스마트 컨트랙트를 설정
  initWeb3: function() {
        // Is there is an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fallback to the TestRPC
      App.web3Provider = new Web3.providers.HttpProvider(App.url);
    }

    web3 = new Web3(App.web3Provider);

    var acc = window.web3.currentProvider.selectedAddress.toString();
    jQuery('#user_id').val(acc);
    web3.eth.getBalance(acc, function(error,result){
      if(error){
        console.log(error)
      }
      else{
        jQuery('#balance').text(web3.fromWei(result.toNumber(), 'ether'));
      }
    });

    ethereum.enable();

    return App.initContract();
  },

  // 컨트랙트 객체 생성
  initContract: function() {
  
    $.getJSON('HUG.json', function(data) {
    // Get the necessary contract artifact file and instantiate it with truffle-contract
    var hugArtifact = data;
    App.contracts.hug = TruffleContract(hugArtifact);

    // Set the provider for our contract
    App.contracts.hug.setProvider(App.web3Provider);
    // button binding
    return App.bindEvents();
    });
  },

  // 버튼에 함수 연결
  bindEvents: function() {
    $(document).on('click', '#join', App.joinHug);
    $(document).on('click', '#refund', App.refundHug);
  },

  // HUG 생성
  joinHug : function(event){
    event.preventDefault();
    
    // 값 받아오기
    var join_fee = parseInt($('#join_fee').text());
    var id_acc = $('#account').text();
    var idnum = $('#id').text().split('(');
    idnum[1] = idnum[1].replace(')', '')
    var num = parseInt(idnum[1]);
    
    App.contracts.hug.deployed().then(function(instance) {
      hugInstance = instance;
      //현재 사이트에서 선택된 계정
      var fromUser = window.web3.currentProvider.selectedAddress.toString();
      // 해당 계정을 from으로 지정해주고 함수 실행
      return hugInstance.join(id_acc, num, {from: fromUser, value: web3.toWei(join_fee,"ether")});
      
    }).then(function(res){
      // 사용된 가스
      $('#gas').val(res.receipt.cumulativeGasUsed);
      // 성공적으로 채굴까지 되면 데이터베이스에 반영
      $('#form').submit();
    }).catch(function(err){
      console.log(err.message);
    })
  },

  // HUG 환불
  refundHug : function(event){
    event.preventDefault();

    // 값 받아오기
    var id_acc = $('#account').text();
    var idnum = $('#id').text().split('(');
    idnum[1] = idnum[1].replace(')', '')
    var num = parseInt(idnum[1]);
    
    // 추후에 평가 페이지 생성시 해당 변수 값도 받아와야 함
    var doit = true;
    var butgo = false;
    var absentlist = [];

    //함수 실행
    App.contracts.hug.deployed().then(function(instance) {
      hugInstance = instance;
      //현재 사이트에서 선택된 계정
      var fromUser = window.web3.currentProvider.selectedAddress.toString();
      // 해당 계정을 from으로 지정해주고 함수 실행
      // return hugInstance.refund(id_acc, num, doit, butgo, absentlist, hug[0].open_gas, hug[0].join_gas, {from: fromUser});
      return hugInstance.refund(id_acc, num, doit, butgo, absentlist, 5000, [100], {from: fromUser});
    }).then(function(res){
      // 결과 출력
      var result = "";
      for(var i = 0; i < res.logs.length; i++){
        result += (i+1)+"번\n" + JSON.stringify(res.logs[i].args) + "\n\n";
      }
      alert(result);

      $('#perform_refund').val(true);
      $('#form2').submit();

    }).catch(function(err){
      console.log(err.message);
    })
  }
};
  
  $(function() {
    $(window).load(function() {
      App.init();
    });
  });
  