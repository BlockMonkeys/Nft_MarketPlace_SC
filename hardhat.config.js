require('dotenv').config({path:__dirname+'/.env'})
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

const {ALCHEMI_GOERLI_ADDRESS, MY_ACCOUNT, ETHERSCAN_API} = process.env;

module.exports = {
  networks : {
    goerli: {
      url: ALCHEMI_GOERLI_ADDRESS,
      accounts: [MY_ACCOUNT]
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API,
  },
  solidity: "0.8.15",
};
