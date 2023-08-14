// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
A collectible can be a single item or a collection of items. Each one with is different price
 */

contract Collectible721 is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCounter;

    string public baseUri;
    uint256 public supply;
    // lockedUntil = 0 leaves the contract opened to transactions
    // a non zero value means it's locked after the time specified by the timestamp
    uint256 public mintPrice;
    uint256 public preMintPrice;
    address[] private allowList;
    uint256 public maxPremintWallets;
    uint256 public maxPremintCollectibles;
    uint256 public preMintEndDate;
    uint256 public publicMintStartDate;
    mapping(uint256 => address) public tokenIdToOwner;
    mapping(address => uint256[]) public ownerToTokenIds;

    event PreMinted(address minter, uint256 itemId);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        uint256 _preMintPrice,
        uint256 _maxPremintWallets,
        uint256 _maxPremintCollectibles,
        uint256 _preMintEndDate,
        uint256 _publicMintStartDate
    ) ERC721(_name, _symbol) {
        require(
            _publicMintStartDate >= 0,
            "You must set a public mint date for the collectibles to be sold"
        );

        publicMintStartDate = _publicMintStartDate;

        if (_mintPrice > 0) {
            mintPrice = _mintPrice;
        }

        if (_preMintPrice > 0) {
            preMintPrice = _preMintPrice;
        }

        if (_maxPremintWallets > 0) {
            maxPremintWallets = _maxPremintWallets;
        }

        if (_maxPremintCollectibles > 0) {
            maxPremintCollectibles = _maxPremintCollectibles;
        }

        if (_preMintEndDate > 0) {
            preMintEndDate = _preMintEndDate;
        }
    }

    // Users are added into a whitelist to mint the items before the public:w

    function premint(
        string memory tokenUri
    ) external payable returns (uint256) {
        uint256 tokenId = tokenIdCounter.current();

        require(
            tokenId < maxPremintCollectibles,
            "The pre-mint items are sold out"
        );

        require(block.timestamp <= preMintEndDate, "The pre-mint sale is over");

        require(msg.value >= preMintPrice, "Not enough funds");

        // Get the available token Ids owned by the caller
        uint256[] memory tokensByOwner = ownerToTokenIds[msg.sender];

        require(
            tokensByOwner.length < maxPremintCollectibles,
            "Maximum collectibles pre-minted by wallet"
        );

        // Push the token to the caller's array of ids
        ownerToTokenIds[msg.sender].push(tokenId);

        // Associate the tokenId to the caller
        tokenIdToOwner[tokenId] = msg.sender;

        emit PreMinted(msg.sender, tokenId);

        // Decrement the collectible's supply
        supply -= 1;

        tokenIdCounter.increment();

        // Mint the token and then set the token URI image
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);

        return tokenId;
    }

    function mint(string memory tokenUri) external payable returns (uint256) {
        uint256 tokenId = tokenIdCounter.current();

        // Users can mint after the public mint date
        require(
            block.timestamp >= publicMintStartDate,
            "The collectibles are not available at public sale for now"
        );

        require(tokenId < supply, "No more collectibles to mint");

        require(msg.value >= mintPrice, "Not enought funds");

        tokenIdCounter.increment();

        tokenId = tokenIdCounter.current();

        tokenIdToOwner[tokenId] = msg.sender;

        ownerToTokenIds[msg.sender].push(tokenId);

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);

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
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
