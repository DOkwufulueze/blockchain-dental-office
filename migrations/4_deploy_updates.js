var contract = require('truffle-contract');
var DBConfigObject = require('../build/contracts/DB.json');

var Setter = artifacts.require("./odll/Setter.sol");

var DBContract = contract(DBConfigObject);
DBContract.setProvider(web3.currentProvider);

var dbAddress = DBContract.deployed()
.then(function(instance) {
  return instance.address;
});

module.exports = function (deployer) {
  deployer.deploy(Setter, dbAddress);
};
