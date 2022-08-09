// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  const deadline = blockBefore.timestamp + 500;

  [deployer, user1, user2, user3, user4, user5] = await ethers.getSigners();
  const MyNFT = await hre.ethers.getContractFactory("MyNFT");
  const LSSVMRouter = await hre.ethers.getContractFactory("LSSVMRouter");
  const myNFT = await MyNFT.deploy();
  const router = await LSSVMRouter.attach("0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329" /* mainnet router */);

  await myNFT.deployed();

  console.log("myNFT:         ", myNFT.address);
  await myNFT.initializeSale("0xb16c1342E617A5B6E4b631EB114483FDB289c0A4" /* mainnet factory */)
  console.log("pair address:  ", await myNFT.getPairAddress());
  console.log("user1 address: ", user1.address);
  console.log("factory: ", await router.factory());
  
  console.log("User1 eth: " + ethers.utils.formatEther(await ethers.provider.getBalance(user1.address)))
  await router.connect(user1).swapETHForAnyNFTs(
    [
      [
        await await myNFT.getPairAddress(),
        1
      ]
    ],
    user1.address, // Excess eth recipient
    user1.address, // NFT recipient
    deadline,
    {value: ethers.utils.parseEther("2")}
  )
  console.log("Contract eth: " + ethers.utils.formatEther(await ethers.provider.getBalance(myNFT.address)))
  console.log("User eth:     " + ethers.utils.formatEther(await ethers.provider.getBalance(user1.address)))

  await router.connect(user1).swapETHForAnyNFTs(
    [
      [
        await await myNFT.getPairAddress(),
        1
      ]
    ],
    user1.address, // Excess eth recipient
    user1.address, // NFT recipient
    deadline,
    {value: ethers.utils.parseEther("2")}
  )
  console.log("Contract eth: " + ethers.utils.formatEther(await ethers.provider.getBalance(myNFT.address)))
  console.log("User eth:     " + ethers.utils.formatEther(await ethers.provider.getBalance(user1.address)))
  console.log("BALANCEE U:     " + await myNFT.balanceOf(user1.address))
  console.log("BALANCEE N:     " + await myNFT.balanceOf(myNFT.address))
  console.log("BALANCEE P:     " + await myNFT.balanceOf(myNFT.getPairAddress()))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
