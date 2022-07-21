const hre = require("hardhat");

async function main() {
  const MonsterNFT_contract = await hre.ethers.getContractFactory("MonsterNFT");
  const monsterNFT = await MonsterNFT_contract.deploy();

  await monsterNFT.deployed();

  console.log("monsterNFT deployed to:", monsterNFT.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
