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

    ethereum.enable();

    return App.initContract();
  },

  // 컨트랙트 객체 생성
  initContract: function() {
      $.getJSON('donsildonsil.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var donsildonsilArtifact = data;
      App.contracts.donsildonsil = TruffleContract(donsildonsilArtifact);

      // Set the provider for our contract
      App.contracts.donsildonsil.setProvider(App.web3Provider);

      // 화면에 정보 계정 정보 띄우기
      App.contracts.donsildonsil.deployed().then(function(instance) {
        donsildonsilInstance = instance;
        return donsildonsilInstance.totalNum();
      }).then(function(totalNum){
        //jQuery('#contract_account').text(totalNum);
        //jQuery('#contract_account2').text(donsildonsilInstance.address.toString());
      }).catch(function(err){
        console.log(err.message);
      })
      // button binding
      return App.bindEvents();
    });
  },
  
  // 버튼에 함수 연결
  bindEvents: function() {
    //$(document).on('click', '#write', App.addInfo);
  },

  // Info 생성
  addInfo : function(event){
    event.preventDefault();
    
    // 값 받아오기
    var judgeType = String($('#judgeType').val());
    var judgeDate = parseInt($('#judgeDate').val());
    var pass = $('#pass').val();

    // 패스 값 불린으로 넣어주기
    if (pass == 0) pass = false;
    else pass = true;

    var age = parseInt($('#age').val());
    var gender = parseInt($('#gender').val());
    var salary = parseInt($('#salary').val());
    var transactionNum = parseInt($('#transactionNum').val());
    var asset = parseInt($('#asset').val());
    var loan = parseInt($('#loan').val());
    var loanDate = parseInt($('#loanDate').val());


    App.contracts.donsildonsil.deployed().then(function(instance) {
      donsildonsilInstance = instance;
      
      //현재 사이트에서 선택된 계정
      var fromUser = window.web3.currentProvider.selectedAddress.toString();
      // 해당 계정을 from으로 지정해주고 함수 실행
      donsildonsilInstance.write(judgeType, judgeDate, pass, age, gender, salary, transactionNum, asset, loan, loanDate, {from: fromUser});
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
