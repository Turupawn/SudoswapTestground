// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ICurve{}

abstract contract LSSVMPair
{
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }
}

contract LSSVMPairETH {
    function changeSpotPrice(uint128 newSpotPrice) external {
    }
}

contract LSSVMPairFactory {
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPairETH pair) {
    }
}

contract MyNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public tokenCounter;
    uint256 public token_count;

    LSSVMPairFactory public factory;
    LSSVMPairETH public nftPair;
    LSSVMPairETH public tokenPair;

    uint public MAX_AMOUNT = 10000;

    uint128 public mintPrice;
    uint128 public autoFloorPrice;
    uint public autoFloorFeePercentage;
    address public autoFloorNFTReciever;
    uint public  FEE_DECIMAL = 2;

    address public a1;
    address public a2;
    address public a3;

    string public baseTokenURI = "https://api.io/";

    // Constructor and init

    constructor() ERC721("My NFT", "MNFT") {
        mintPrice = 0.04 ether;
        autoFloorPrice = 0.02 ether;
        autoFloorFeePercentage = 5000; // 50%
        autoFloorNFTReciever = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        a1 = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        a2 = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
        a3 = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    }

    function initializeSale(address factoryAddress) public {
        factory = LSSVMPairFactory(factoryAddress);
        uint[] memory initialNFTIDs = new uint[](10);
        address payable recipient = payable(this);

        while(tokenCounter.current()<10)
        {
            initialNFTIDs[tokenCounter.current()] = tokenCounter.current();
            _mint(address(this),tokenCounter.current());
            _approve(factoryAddress, tokenCounter.current());
            tokenCounter.increment();
        }

        nftPair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee), // Lineal
            recipient,  // This contract
            LSSVMPair.PoolType.NFT,// NFT, TOKEN, TRADE
            0e18,       // Delta
            0,          // Fee
            mintPrice,  // Initial price
            initialNFTIDs
        );

        uint[] memory emptyArray = new uint[](0);
        tokenPair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee), // Lineal
            payable(autoFloorNFTReciever), // This contract
            LSSVMPair.PoolType.TOKEN,// NFT, TOKEN, TRADE
            0e18,       // Delta
            0,          // Fee
            autoFloorPrice, // Initial price
            emptyArray
        );
    }

    // View functions

    function getNFTPairAddress() public view returns(address) {
        return address(nftPair);
    }

    function getTokenPairAddress() public view returns(address) {
        return address(tokenPair);
    }

    // Override functions

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721)
    {
        if(from != address(0))
        {
            if(from == address(nftPair) && uint(tokenCounter.current()) < MAX_AMOUNT)
            {
                _mint(address(nftPair), tokenCounter.current());
                tokenCounter.increment();
            }
        }
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
        data;
        _transfer(from, to, tokenId);
    }

    // Owner functions

    function setAutoFloorFeePercentage(uint value) public onlyOwner
    {
        autoFloorFeePercentage = value;
    }

    function setMintPrice(uint128 value) public onlyOwner
    {
        mintPrice = value;
        nftPair.changeSpotPrice(value);
    }

    function setAutoFloorPrice(uint128 value) public onlyOwner
    {
        autoFloorPrice = value;
        tokenPair.changeSpotPrice(value);
    }

    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
    }

    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        bool sent;
        bytes memory data;
        (sent, data) = payable(a1).call{value: percent * 40}("");
        require(sent, "Failed to send Ether");
        (sent, data) = payable(a2).call{value: percent * 30}("");
        require(sent, "Failed to send Ether");
        (sent, data) = payable(a3).call{value: percent * 30}("");
        require(sent, "Failed to send Ether");
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Fallback functions

    fallback() external payable {
    }

    receive() external payable {
        uint256 transferAmount = (msg.value) * (autoFloorFeePercentage) / (10**(FEE_DECIMAL + 2));
        (bool sent, bytes memory data) = address(tokenPair).call{value: transferAmount}("");
        data;
        require(sent, "Failed to send Ether");
    }
}