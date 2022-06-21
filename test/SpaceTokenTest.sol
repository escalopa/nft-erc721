// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../contracts/SpaceToken.sol";

contract SpaceTokenTest {
    SpaceToken spaceToken;

    function beforeEach() public {
        spaceToken = new SpaceToken();
    }

    function testMintToken() public {
        string memory url = "http://example.com";
        address minter = tx.origin;

        // Mint new NFT and get tokenId
        uint256 tokenId = spaceToken.mintToken(minter, url);

        //  Asset that token belongs to minter
        require(
            minter == (spaceToken.ownerOf(tokenId)),
            "Token owener should be minter"
        );
    }

    function testGetTokensDetails() public {
        // Tokens creator
        address owner = tx.origin;

        // Mint testTokens
        string memory url1 = "https://www.google.com/token/1";
        string memory url2 = "https://www.google.com/token/2";
        spaceToken.mintToken(owner, url1);
        spaceToken.mintToken(owner, url2);

        SpaceToken.TokenDetails[] memory tokens = spaceToken.getTokensDetails(
            owner
        );

        require(
            tokens.length == 2,
            "Tokens lenght should be 2 (count of minted tokens)"
        );

        require(
            keccak256(bytes(url1)) == keccak256(bytes(tokens[0].url)),
            "URL of 1 token must match"
        );

        require(
            keccak256(bytes(url2)) == keccak256(bytes(tokens[1].url)),
            "URL of 2 token must match"
        );
    }

    // Fails because of modifier (OnlyTokenOwner)
    function testUpdateTokenDetails() public {
        address owner = tx.origin;
        string memory url = "http://localhost:8080";
        string memory description = "token description";
        string memory iconHash = "token icon hash";
        string memory screenshotHash = "token screenshot hash";

        // Mint token and get id
        uint256 tokenId = spaceToken.mintToken(owner, url);

        // Update token
        spaceToken.updateTokenDetials(
            tokenId,
            description,
            iconHash,
            screenshotHash
        );

        // Fetch token details by id for testing updateTokenDetials
        SpaceToken.TokenDetails memory tokenDetails = spaceToken
            .getTokenDetailsById(tokenId);

        require(
            keccak256(bytes(description)) ==
                keccak256(bytes(tokenDetails.description)),
            "Token description must be the same"
        );

        require(
            keccak256(bytes(iconHash)) ==
                keccak256(bytes(tokenDetails.iconHash)),
            "Token iconHash must be the same"
        );

        require(
            keccak256(bytes(screenshotHash)) ==
                keccak256(bytes(tokenDetails.screenshotHash)),
            "Token screenshotHash must be the same"
        );
    }

    // function testSender() public view {
    //     require(
    //         address(this) == tx.origin,
    //         "Contract address is the sender address"
    //     );
    // }
}
