const Web3 = require('web3');
var Ballot = artifacts.require("Ballot");

module.exports = function(deployer) {
	deployer.deploy(Ballot,4);
};
