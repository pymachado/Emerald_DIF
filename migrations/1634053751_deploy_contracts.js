const NFT_FACTORY = artifacts.require("NFT_FACTORY");
module.exports = async function(deployer) {
  await deployer.deploy(NFT_FACTORY);
  // Use deployer to state migration tasks.
};
