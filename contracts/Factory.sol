// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC20{}

contract ICurve{}

abstract contract LSSVMPair
{
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }
}

contract LSSVMPairETH{}

contract LSSVMPairERC20{}

contract PairVariant{}

contract LSSVMPairFactory {
    /**
     * External functions
     */

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
        @param _spotPrice The initial selling spot price, in ETH
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @param _initialTokenBalance The initial token balance sent from the sender to the new pair
        @return pair The new pair
     */
    struct CreateERC20PairParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        LSSVMPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function createPairERC20(CreateERC20PairParams calldata params)
        external
        returns (LSSVMPairERC20 pair)
    {
    }

    /**
        @notice Checks if an address is a LSSVMPair. Uses the fact that the pairs are EIP-1167 minimal proxies.
        @param potentialPair The address to check
        @param variant The pair variant (NFT is enumerable or not, pair uses ETH or ERC20)
        @return True if the address is the specified pair variant, false otherwise
     */
    function isPair(address potentialPair, PairVariant variant)
        public
        view
        returns (bool)
    {
    }
}

contract MyNFT is ERC721 {
    uint256 public token_count;

    LSSVMPairFactory public factory;
    LSSVMPairETH public pair;

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
        pair = factory.createPairETH(
            IERC721(address(this)),
            ICurve(0x432f962D8209781da23fB37b6B59ee15dE7d9841), // Exponential
            recipient, // This contract
            LSSVMPair.PoolType.NFT,// NFT, TOKEN, TRADE
            1.1e18,     // Delta
            0,          // Fee
            1 ether, // Initial price
            initialNFTIDs
        );
    }

    function getPairAddress() public view returns(address) {
        return address(pair);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "https://ipfs.io/ipfs/TUHASHAQUI";
    }

    function mintNFT(address to) public
    {
        token_count  += 1;
        _mint(to, token_count);
    }

    fallback() external payable {
    }
    receive() external payable {
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721)
    {
        if(from == address(pair) && from != address(0))
        {
            _mint(address(this), token_count);
            token_count += 1;
            //_approve(factoryAddress, token_count);
        }
        super._afterTokenTransfer(from, to, tokenId);
    }
}