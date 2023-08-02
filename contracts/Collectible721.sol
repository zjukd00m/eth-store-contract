// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Collectible721 is ERC721, ERC721Burnable, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCounter;

    string public collectibleName;
    string public collectibleSymbol;
    mapping(uint256 => address) public tokenIdToOwner;
    uint256 public collectiblePrice;
    // When the NFT owner address is different than the deployer one
    // then each time the collectible is sell the original creator
    // gets rewarded with a % of the transfered ETH
    address public creatorEarningsAddress;
    uint256 public creatorEarningsPercent;

    // A hidden collectible will not display the real collectible image
    bool public isHidden;
    string public hiddenCover;

    constructor(
        string memory _collectibleName,
        string memory _collectibleSymbol,
        uint256 _collectiblePrice,
        address memory _creatorEarningsAddress,
        uint256 _creatorEarningsPercent,
        bool _isHidden,
        string _hiddenCover,
    ) ERC721(_collectibleName, _collectibleSymbol) {
        collectibleName = _collectibleName;
        collectibleSymbol = _collectibleSymbol;
        collectiblePrice = _collectiblePrice;

        require(_creatorEarningsPercent >= 0 && _creatorEarningsPercent <= 10, "The original owner's NFT earning percentage must be a value between 0 and 10");
        
        creatorEarningsAddress = _creatorEarningsAddress;
        creatorEarningsPercent = _creatorEarningsPercent;

        isHidden = _isHidden;

        hiddenCover = _hiddenCover;

        // The payment shares are set once at the contract deployment event
        // and the release() function must be called manually to transfer the holded ether
        if (_creatorEarningsAddress.length && _creatorEarningsPercent > 0) {
            PaymentSplitter([_creatorEarningsAddress], [_creatorEarningsPercent]);
        }
    }

    function safeMint(address to) public OnlyOwner {
        // The amount of eth the sender sent must be gte than the collectible price
        require(msg.value >= collectiblePrice, "Insuficient balance");

        tokenIdCounter.increment();
        uint256 _tokenId = tokenIdCounter.current();

        // Associate the tokenId with the buyer
        tokenIdToOwner[msg.sender] = _tokenId;

        // Add the creator earnings if the current owner is not the smart contract deployer
        // if (owner.)

        _safeMint(to, _tokenId);
    }

    // Mark the contract as hidden/not-hidden
    function setIsHidden(bool _isHidden) public onlyOwner {
        isHidden = _isHidden;

        // TODO: Modify the collectible URI if it's hidden (show a default cover or a user defined one)
    }

    // Override functions required by solidity

    function _burn(
        uint256 _tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(_tokenId);
    }

    // Check for the additional interface ID that will be supported
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}
