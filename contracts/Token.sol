// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

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
    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
        @param _poolType TOKEN, NFT, or TRADE
        @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param _spotPrice The initial selling spot price
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @return pair The new pair
     */
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

contract MyNFT is ERC721Enumerable {
    uint256 public token_count;

    uint public MAX_AMOUNT = 10000;

    LSSVMPairFactory public factory;
    LSSVMPairETH public nftPair;
    LSSVMPairETH public tokenPair;
    LSSVMPairETH public tradePair;

    uint public  feeDecimal = 2;
    uint public autoFloorPercentage = 9000; // 90%

    constructor() ERC721("My NFT", "MNFT") {
    }

    function initializeSale(address factoryAddress) public {
        factory = LSSVMPairFactory(factoryAddress);
        uint[] memory initialNFTIDs = new uint[](10);
        address payable recipient = payable(this);
        for(; token_count<10; token_count+=1)
        {
            initialNFTIDs[token_count] = token_count;
            _mint(address(this),token_count);
            _approve(factoryAddress, token_count);
        }
        nftPair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee), // Lineal
            recipient, // This contract
            LSSVMPair.PoolType.NFT,// NFT, TOKEN, TRADE
            0.0001e18,     // Delta
            0,          // Fee
            0.01 ether, // Initial price
            initialNFTIDs
        );

        uint[] memory emptyArray = new uint[](0);
        tokenPair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x5B6aC51d9B1CeDE0068a1B26533CAce807f883Ee), // Lineal
            recipient, // This contract
            LSSVMPair.PoolType.TOKEN,// NFT, TOKEN, TRADE
            0e18,     // Delta
            0,          // Fee
            9999 ether, // Initial price
            emptyArray
        );

        tradePair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x432f962D8209781da23fB37b6B59ee15dE7d9841), // Exponential
            payable(0), // This contract
            LSSVMPair.PoolType.TRADE,// NFT, TOKEN, TRADE
            1.001e18,     // Delta
            5,          // Fee
            0.001 ether, // Initial price
            emptyArray
        );
    }

    function getNFTPairAddress() public view returns(address) {
        return address(nftPair);
    }

    function getTokenPairAddress() public view returns(address) {
        return address(tokenPair);
    }

    fallback() external payable {
    }

    receive() external payable {
        uint256 transferAmount = (address(this).balance) * (autoFloorPercentage) / (10**(feeDecimal + 2));
        (bool sent, bytes memory data) = address(tokenPair).call{value: transferAmount}("");
        data;

        updateSpotPrice();

        require(sent, "Failed to send Ether");
    }

    function updateSpotPrice() internal
    {
        uint128 newSpotPrice = (uint128)((address(this).balance) / (MAX_AMOUNT - balanceOf(address(this))));
        tokenPair.changeSpotPrice(newSpotPrice);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721)
    {
        if(from != address(0))
        {
            if(from == address(nftPair))
            {
                _mint(address(this), token_count);
                _approve(address(nftPair), token_count);
                _transfer(
                    address(this),
                    address(nftPair),
                    token_count
                );
                token_count += 1;
                //_approve(factoryAddress, token_count);
            }
            if(from == address(tokenPair))
            {
                updateSpotPrice();
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
    function setFeeDecimal(uint value) public
    {
        feeDecimal = value;
    }

    function setAutoFloorPercentage(uint value) public
    {
        autoFloorPercentage = value;
    }

    function withdrawFunds() public
    {
        (bool sent, bytes memory data) = address(msg.sender).call{value: address(this).balance}("");
        data;
        require(sent, "Failed to send Ether");
    }
}