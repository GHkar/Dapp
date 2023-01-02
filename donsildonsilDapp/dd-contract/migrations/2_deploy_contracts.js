const Web3 = require('web3');
var donsildonsil = artifacts.require("donsildonsil");

module.exports = function(deployer) {
	deployer.deploy(donsildonsil);
};
