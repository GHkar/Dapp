let Web3 = require('web3');

let web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));

web3.eth.getBlockNumber((err, blockCount) => {
        console.log(blockCount)
})
