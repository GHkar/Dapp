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
  
      return App.show();
    },
  
    // 아이디 보여주기
    show: function() {
    
        var selectedUser = window.web3.currentProvider.selectedAddress.toString();
        jQuery('#account_addr').val(selectedUser);
    }
  };
  
  
  $(function() {
    $(window).load(function() {
      App.init();
    });
  });
  