// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
A collectible can be a single item or a collection of items. Each one with is different price
 */

contract Collectible721 is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCounter;

    string private baseURI;
    uint256 public maxSupply;
    uint256 public preMintPrice;
    uint256 public preMintStartDate;
    uint256 public preMintEndDate;
    uint256 public maxPreMintCollectibles;
    uint256 public maxPreMintCollectiblesPerWallet;

    uint256 public publicMintPrice;
    uint256 public publicMintStartDate;
    uint256 public maxCollectiblesPerWallet;

    mapping(address => uint256[]) public ownerToTokenIds;

    event PreMinted(address indexed minter, uint256 indexed itemId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256[2] memory _collectiblePrices,
        uint256[2] memory _preMintDates,
        uint256[2] memory _maxMintCollectiblesPerWallet,
        uint256 _maxPreMintCollectibles,
        uint256 _maxSupply,
        uint256 _publicMintStartDate
    ) ERC721(_name, _symbol) {
        require(
            _collectiblePrices.length == 2,
            "_collectiblePrices variable must be of length 2"
        );

        require(
            _maxMintCollectiblesPerWallet.length == 2,
            "_maxMintCollectiblesPerWallet must be of length 2"
        );

        require(
            bytes(_baseUri).length > 0,
            "You must set the base URI for the tokens"
        );

        require(
            _maxSupply > 0,
            "Max collectible supply must be greater than 0"
        );

        require(
            _collectiblePrices[1] > 0,
            "You must set the public mint collectible price"
        );

        require(
            _maxPreMintCollectibles > 0,
            "You must set a limit for the pre-mint colletibles to be created"
        );

        maxSupply = _maxSupply;

        baseURI = _baseUri;

        publicMintPrice = _collectiblePrices[1];

        maxPreMintCollectibles = _maxPreMintCollectibles;

        // Public mint start date may be as soon as the moment it's deployed
        if (_publicMintStartDate > 0)
            publicMintStartDate = _publicMintStartDate;

        // If the pre-mint items will have a price (on pre-mint enables)
        if (_collectiblePrices[0] > 0) preMintPrice = _collectiblePrices[0];

        // Start and end dates of the pre-mint
        if (
            _preMintDates.length == 2 &&
            _preMintDates[0] > 0 &&
            _preMintDates[1] > 0
        ) {
            preMintStartDate = _preMintDates[0];
            preMintEndDate = _preMintDates[1];
        }

        if (_maxMintCollectiblesPerWallet[0] > 0)
            maxPreMintCollectiblesPerWallet = _maxMintCollectiblesPerWallet[0];

        if (_maxMintCollectiblesPerWallet[1] > 0)
            maxCollectiblesPerWallet = _maxMintCollectiblesPerWallet[1];
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function premint(uint8 _amount) external payable {
        require(
            preMintPrice > 0,
            "Premint is not enabled for this collectible"
        );

        require(
            block.timestamp >= preMintStartDate,
            "The pre-mint sale hasn't started yet"
        );

        require(_amount > 0, "Can't mint 0 collectibles");

        require(
            totalSupply() + _amount <= maxPreMintCollectibles,
            "The pre-mint items are sold out"
        );

        require(block.timestamp <= preMintEndDate, "The pre-mint sale is over");

        require(msg.value >= _amount * preMintPrice, "Not enough funds");

        if (maxPreMintCollectiblesPerWallet > 0)
            require(
                balanceOf(msg.sender) + _amount <
                    maxPreMintCollectiblesPerWallet,
                "Maximum collectibles pre-minted by wallet"
            );

        for (uint8 i = 0; i < _amount; i++) {
            tokenIdCounter.increment();

            uint256 tokenId = tokenIdCounter.current();

            string memory tokenUri = makeTokenURI(tokenId);

            _safeMint(msg.sender, tokenId);

            _setTokenURI(tokenId, tokenUri);

            ownerToTokenIds[msg.sender].push(tokenId);

            emit PreMinted(msg.sender, tokenId);
        }
    }

    function publicMint(uint8 _amount) external payable {
        if (publicMintStartDate > 0)
            require(
                block.timestamp >= publicMintStartDate,
                "The collectibles are not available for public sale for now"
            );

        require(totalSupply() + _amount <= maxSupply, "Sold Out");

        if (maxCollectiblesPerWallet > 0)
            require(
                balanceOf(msg.sender) + _amount <= maxCollectiblesPerWallet,
                "Maximum collectibles per wallet minted"
            );

        require(msg.value >= _amount * publicMintPrice, "Not enough funds");

        for (uint8 i = 0; i < _amount; i++) {
            tokenIdCounter.increment();

            uint256 tokenId = tokenIdCounter.current();

            string memory tokenUri = makeTokenURI(tokenId);

            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, tokenUri);

            ownerToTokenIds[msg.sender].push(tokenId);
        }
    }

    function makeTokenURI(
        uint256 tokenId
    ) private view returns (string memory) {
        require(bytes(_baseURI()).length > 0, "The base URI is not set");

        return string(abi.encodePacked(Strings.toString(tokenId), ".json"));
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }
}
