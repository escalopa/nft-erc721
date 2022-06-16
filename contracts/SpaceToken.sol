// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpaceToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct TokenDetails {
        string url;
        string description;
        string iconHash;
        string screenshotHash;
        uint256 lastWithdrawDate;
    }

    event WithdrawAction(address owner, address to, uint256 amount);

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId));
        _;
    }

    // Map from tokenId to tokenData
    mapping(address => uint256[]) public _userTokenIds;

    // TokenId to it's details
    mapping(uint256 => TokenDetails) public _tokenDetails;

    // Map address to lastWithdrawDate
    // mapping(address => uint256) public _penddingWithdraws;

    constructor() ERC721("SpaceToken", "SPTK") {}

    // Create a token with siteUrl & Token Details
    function mintToken(address owner, TokenDetails memory tokenDetails)
        public
        returns (uint256)
    {
        uint256 tokenId = _tokenIds.current();
        _mint(owner, tokenId);
        _setTokenURI(tokenId, tokenDetails.url);

        _userTokenIds[owner].push(tokenId);

        // Set lastWithdrawDate as init date
        tokenDetails.lastWithdrawDate = block.timestamp;
        _tokenDetails[tokenId] = tokenDetails;

        _tokenIds.increment();

        return tokenId;
    }

    /**
     * @param owner An address of a user of which we want to get his tokens
     */
    function getTokenDetails(address owner)
        public
        view
        returns (TokenDetails[] memory tokenDetails)
    {
        // Get all user tokenIds
        uint256[] memory userTokenIds = _userTokenIds[owner];

        // Loop through all tokenIds to get their details
        for (uint256 i = 0; i < userTokenIds.length; i++) {
            tokenDetails[i] = _tokenDetails[userTokenIds[i]];
        }

        return tokenDetails;
    }

    // Claim earned ETH
    function withdrawEarnedTokens(
        address payable to,
        uint256 amount,
        uint256 tokenId
    ) external payable virtual onlyTokenOwner(tokenId) {
        // Get amount of wei to send
        uint256 earnedTokens = getEarnedTokens(tokenId);

        require(
            amount <= earnedTokens,
            "Withdraw amount exceeds earned tokens count"
        );

        // Set wihtdraw date as NOW timestamp
        _tokenDetails[tokenId].lastWithdrawDate = block.timestamp;

        // Send earned tokens
        to.transfer(amount);

        emit WithdrawAction(_msgSender(), to, amount);
    }

    /**
     * @return amount ,in wei
     */
    function getEarnedTokens(uint256 tokenId)
        private
        view
        returns (uint256 amount)
    {
        uint256 lastWithdrawDate = _tokenDetails[tokenId].lastWithdrawDate;

        // amonut = timepassed in seconds / 60 (to minutes) / 24 (to days)
        uint256 daysPassed = (block.timestamp - lastWithdrawDate) / 60 / 24;

        amount = daysPassed * 10**16;
    }
}
