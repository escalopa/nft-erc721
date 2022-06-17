const SpaceToken = artifacts.require("SpaceToken");

module.exports = function (deployer) {
  deployer.deploy(SpaceToken);
};
