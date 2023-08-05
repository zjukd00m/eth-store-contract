// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Items is Ownable {
    using Counters for Counters.Counter;

    struct Item {
        string name;
        string description;
        string pictureURL;
        string metadataURL;
    }

    string public name;
    string public symbol;

    mapping(uint256 => Item) public itemIdToItem;

    Counters.Counter private tokenIdCounter;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function addItem(
        string memory _name,
        string memory _description,
        string memory _pictureURL,
        string memory _metadataURL
    ) public onlyOwner returns (Item memory) {
        tokenIdCounter.increment();
        uint256 _tokenId = tokenIdCounter.current();

        Item memory _item = Item({
            name: _name,
            description: _description,
            pictureURL: _pictureURL,
            metadataURL: _metadataURL
        });

        itemIdToItem[_tokenId] = _item;

        return _item;
    }

    function editItem(
        uint256 _itemId,
        string memory _name,
        string memory _description,
        string memory _pictureURL,
        string memory _metadataURL
    ) public onlyOwner {
        require(_itemId <= tokenIdCounter.current(), "The item doesn't exist");

        Item storage item = itemIdToItem[_itemId];

        if (bytes(_name).length > 0) {
            item.name = _name;
        }

        if (bytes(_description).length > 0) {
            item.description = _description;
        }

        if (bytes(_pictureURL).length > 0) {
            item.pictureURL = _pictureURL;
        }

        if (bytes(_metadataURL).length > 0) {
            item.metadataURL = _metadataURL;
        }
    }
}
