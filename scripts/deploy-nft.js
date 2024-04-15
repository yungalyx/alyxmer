const hre = require("hardhat");


async function main() {

  const networkName = hre.network.name;
  const myContract = await hre.ethers.deployContract("NFT");
  await myContract.waitForDeployment();

// NOTE: Do not change the output string, its output is formatted to be used in the deploy-config.js script
// to update the config.json file
console.log(`
✅   Deployment Successful   ✅
-------------------------------
📍 Address: ${myContract.target}
🌍 Network: ${networkName}
-------------------------------\n
`);

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});