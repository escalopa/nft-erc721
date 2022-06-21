// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SpaceToken is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("SpaceToken", "SPTK") {}

    struct TokenDetails {
        string url;
        string description;
        string iconHash;
        string screenshotHash;
        uint256 lastWithdrawDate;
    }

    event MintToken(address owner, string url);
    event WithdrawAction(address owner, uint256 tokenId, uint256 amount);

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId));
        _;
    }

    // Map from tokenId to tokenData
    mapping(address => uint256[]) public _minterTokenIds;

    // from tokenId to it's details
    mapping(uint256 => TokenDetails) public _tokenDetails;

    /**
     * @param owner Token minter address
     * @param url String representing the url of website
     * @return tokenId id of created NFT
     */
    function mintToken(address owner, string memory url)
        public
        returns (uint256 tokenId)
    {
        tokenId = _tokenIds.current();
        _mint(owner, tokenId);
        _setTokenURI(tokenId, url);

        _minterTokenIds[owner].push(tokenId);

        emit MintToken(owner, url);

        // Prepare token details for save
        TokenDetails memory tokenDetails;
        tokenDetails.url = url;
        tokenDetails.lastWithdrawDate = block.timestamp;

        // Push tokendatails to map
        _tokenDetails[tokenId] = tokenDetails;

        _tokenIds.increment();
        return tokenId;
    }

    function getTokenDetailsById(uint256 tokenId)
        public
        view
        returns (TokenDetails memory token)
    {
        return _tokenDetails[tokenId];
    }

    /**
     * @param owner An address of a user of which we want to get his tokens
     * @return tokens List of Tokens with all details about each
     */
    function getTokensDetails(address owner)
        public
        view
        returns (TokenDetails[] memory)
    {
        // Get all user tokenIds
        uint256[] memory userTokenIds = _minterTokenIds[owner];

        // Loop through all tokenIds to get their details
        TokenDetails[] memory tokens = new TokenDetails[](userTokenIds.length);

        for (uint256 i = 0; i < userTokenIds.length; i++) {
            tokens[i] = _tokenDetails[userTokenIds[i]];
        }

        return tokens;
    }

    function updateTokenDetials(
        uint256 tokenId,
        string calldata description,
        string calldata iconHash,
        string calldata screenshotHash
    ) public virtual onlyTokenOwner(tokenId) {
        // Get token by id
        TokenDetails memory token = _tokenDetails[tokenId];

        // Update token details
        token.description = description;
        token.iconHash = iconHash;
        token.screenshotHash = screenshotHash;

        _tokenDetails[tokenId] = token;
    }

    /**
     * @return amount in wei
     */
    function getEarnedTokens(uint256 tokenId)
        public
        view
        returns (uint256 amount)
    {
        uint256 lastWithdrawDate = _tokenDetails[tokenId].lastWithdrawDate;

        // amonut = timepassed in seconds / 60 (to minutes) / 24 (to days)
        uint256 daysPassed = (block.timestamp - lastWithdrawDate) / 60 / 24;

        amount = daysPassed * 10**16;
    }

    // Claim earned ETH
    function withdrawEarnedTokens(uint256 amount, uint256 tokenId)
        external
        payable
        virtual
        onlyTokenOwner(tokenId)
    {
        // Get amount of wei to send
        uint256 earnedTokens = getEarnedTokens(tokenId);

        require(
            amount <= earnedTokens,
            "Withdraw amount exceeds earned tokens count"
        );

        // Set wihtdraw date as NOW timestamp
        _tokenDetails[tokenId].lastWithdrawDate = block.timestamp;

        // Send earned tokens
        payable(_msgSender()).transfer(amount);

        emit WithdrawAction(_msgSender(), tokenId, amount);
    }
}
