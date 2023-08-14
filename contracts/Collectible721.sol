// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
A collectible can be a single item or a collection of items. Each one with is different price
 */

contract Collectible721 is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCounter;

    string public baseUri;
    uint256 public maxSupply;
    // lockedUntil = 0 leaves the contract opened to transactions
    // a non zero value means it's locked after the time specified by the timestamp
    uint256 public preMintPrice;
    uint256 public preMintStartDate;
    uint256 public preMintEndDate;
    uint256 public maxPreMintCollectibles;
    uint256 public maxPreMintCollectiblesPerWallet;

    uint256 public publicMintPrice;
    uint256 public publicMintStartDate;

    // mapping(uint256 => address) public tokenIdToOwner;
    // mapping(address => uint256[]) public ownerToTokenIds;

    event PreMinted(address minter, uint256 itemId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _maxSupply,
        uint256 _preMintPrice,
        uint256 _preMintStartDate,
        uint256 _preMintEndDate,
        uint256 _maxPreMintCollectibles,
        uint256 _maxPreMintCollectiblesPerWallet,
        uint256 _publicMintPrice,
        uint256 _publicMintStartDate
    ) ERC721(_name, _symbol) {
        require(
            _maxSupply > 0,
            "Max collectible supply must be greater than 0"
        );

        require(
            _publicMintStartDate >= 0,
            "You must set a public mint date for the collectibles to be sold"
        );

        require(
            _publicMintPrice > 0,
            "You must set an amount in WEI for the public mint price"
        );

        require(
            bytes(_baseUri).length > 0,
            "You must set the base Uri for the tokens"
        );

        maxSupply = _maxSupply;

        publicMintStartDate = _publicMintStartDate;

        publicMintPrice = _publicMintPrice;

        if (_preMintPrice > 0) preMintPrice = _preMintPrice;

        if (_preMintStartDate > 0) preMintStartDate = _preMintStartDate;

        if (_preMintEndDate > 0) preMintEndDate = _preMintEndDate;

        if (_maxPreMintCollectibles > 0)
            maxPreMintCollectibles = _maxPreMintCollectibles;

        if (_maxPreMintCollectiblesPerWallet > 0)
            maxPreMintCollectiblesPerWallet = _maxPreMintCollectiblesPerWallet;
    }

    // Users are added into a whitelist to mint the items before the public:w

    function premint(
        string memory tokenUri
    ) external payable returns (uint256) {
        tokenIdCounter.increment();

        uint256 tokenId = tokenIdCounter.current();

        require(
            tokenId <= maxPreMintCollectibles,
            "The pre-mint items are sold out"
        );

        require(block.timestamp <= preMintEndDate, "The pre-mint sale is over");

        require(msg.value >= preMintPrice, "Not enough funds");

        require(
            balanceOf(msg.sender) < maxPreMintCollectiblesPerWallet,
            "Maximum collectibles pre-minted by wallet"
        );

        // Push the token to the caller's array of ids
        // ownerToTokenIds[msg.sender].push(tokenId);

        // Associate the tokenId to the caller
        // tokenIdToOwner[tokenId] = msg.sender;

        emit PreMinted(msg.sender, tokenId);

        // Mint the token and then set the token URI image
        _setTokenURI(tokenId, tokenUri);
        _safeMint(msg.sender, tokenId);

        return tokenId;
    }

    function publicMint(
        string memory tokenUri
    ) external payable returns (uint256) {
        // Users can mint after the public mint date
        require(
            block.timestamp >= publicMintStartDate,
            "The collectibles are not available at public sale for now"
        );

        require(totalSupply() <= maxSupply, "No more collectibles to mint");

        require(msg.value >= publicMintPrice, "Not enought funds");

        tokenIdCounter.increment();

        uint256 tokenId = tokenIdCounter.current();

        // tokenIdToOwner[tokenId] = msg.sender;

        // ownerToTokenIds[msg.sender].push(tokenId);

        _setTokenURI(tokenId, tokenUri);
        _safeMint(msg.sender, tokenId);

        return tokenId;
    }

    // Function overrides
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
