// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

var deadline
var router
var myNFT
var nftPair
var tokenPair

async function getAutofloorPrice()
{
  token_sell_quote = await tokenPair.getSellNFTQuote(1)
  return ethers.utils.formatEther(token_sell_quote[3])
}

async function getMintPrice()
{
  nft_buy_quote = await nftPair.getBuyNFTQuote(1)
  return ethers.utils.formatEther(nft_buy_quote[3])
}

async function printPairState()
{
  console.log("Prices")
  console.log("======")
  console.log("Mint:      " + await getMintPrice() + " ETH")
  console.log("Autofloor: " + await getAutofloorPrice() + " ETH")
  console.log("")
}

async function printETHBalances()
{
  console.log("ETH Balances")
  console.log("============")
  console.log("NFT Contract: " + ethers.utils.formatEther(await ethers.provider.getBalance(myNFT.address)))
  console.log("User1:        " + ethers.utils.formatEther(await ethers.provider.getBalance(user1.address)))
  console.log("Token Pair:   " + ethers.utils.formatEther(await ethers.provider.getBalance(tokenPair.address)))
  console.log("")
}

async function printNFTBalances()
{
  console.log("NFT Balances")
  console.log("============")
  console.log("User1:        " + await myNFT.balanceOf(user1.address))
  console.log("NFT Contract: " + await myNFT.balanceOf(myNFT.address))
  console.log("NFT Pair:     " + await myNFT.balanceOf(myNFT.getNFTPairAddress()))
  console.log("Token Pair:   " + await myNFT.balanceOf(myNFT.getTokenPairAddress()))
  console.log("")
}

async function buyNFT(etherAmount)
{
  console.log("We buy an NFT for " + etherAmount + " ETH ")
  console.log("")
  await router.connect(user1).swapETHForAnyNFTs(
    [
      [
        await myNFT.getNFTPairAddress(),
        1
      ]
    ],
    user1.address, // Excess eth recipient
    user1.address, // NFT recipient
    deadline,
    {value: ethers.utils.parseEther(etherAmount)}
  )
}

async function sellNFT(holder, etherAmount)
{
  console.log("We sell an NFT for " + etherAmount + " ETH")
  console.log("")

  var tokenId = myNFT.tokenOfOwnerByIndex(holder.address, 0)
  await myNFT.connect(holder).approve(router.address, tokenId)
  await router.connect(holder).swapNFTsForToken(
    [
      [
        await myNFT.getTokenPairAddress(),
        [tokenId]
      ]
    ],
    ethers.utils.parseEther(etherAmount),
    holder.address,
    deadline
  )
}

async function main() {
  ///////////////////////////////////
  ////////// Hardhat setup //////////
  ///////////////////////////////////
  const blockNumBefore = await ethers.provider.getBlockNumber();
  const blockBefore = await ethers.provider.getBlock(blockNumBefore);
  deadline = blockBefore.timestamp + 999999;

  [deployer, user1, user2, user3, user4, user5] = await ethers.getSigners();
  const MyNFT = await hre.ethers.getContractFactory("MyNFT");
  const LSSVMRouter = await hre.ethers.getContractFactory("LSSVMRouter");
  const LSSVMPair = await hre.ethers.getContractFactory("ILSSVMPair");
  router = await LSSVMRouter.attach("0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329" /* mainnet router */);

  ///////////////////////////////////
  ////////// Deploy & Init //////////
  ///////////////////////////////////
  myNFT = await MyNFT.deploy();
  await myNFT.deployed();

  // Init stuff
  await myNFT.initializeSale("0xb16c1342E617A5B6E4b631EB114483FDB289c0A4" /* mainnet factory */)
  nftPair = await LSSVMPair.attach(await myNFT.getNFTPairAddress())
  tokenPair = await LSSVMPair.attach(await myNFT.getTokenPairAddress())
  await deployer.sendTransaction({
    to: await await myNFT.getTokenPairAddress(),
    value: ethers.utils.parseEther("1.0"),
  });

  //await printPairState()

  ///////////////////////////////////
  ///////////// Buy NFT /////////////
  ///////////////////////////////////
  
  await printPairState()
  await buyNFT(await getMintPrice())
  await printPairState()
  await buyNFT(await getMintPrice())
  await printPairState()
  /*
  for(i=0;i<9000;i++)
  {
    console.log(i)
    await buyNFT(await getMintPrice())
    console.log("Auto floor: " + await getAutofloorPrice())
  }
  */
  await sellNFT(user1, await getAutofloorPrice())
  await printPairState() 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
