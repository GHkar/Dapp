const Web3 = require('web3');
var HUG = artifacts.require("HUG");

module.exports = function(deployer) {
        deployer.deploy(HUG);
};
