// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Badge is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIdCounter;

    struct BadgeItem {
        string name;
        string description;
        uint256 itemUrl;
        uint8 level;
        string condition;
    }

    // A badge has a limit of users to be granted
    mapping(uint256 tokenId => BadgeItem) public tokenIdToBadgeItem;
    mapping(uint256 tokenId => address[]) public tokenIdToOwners;

    constructor() {}

    function mintBadge() external onlyOwner {}

    // The badge must be minted before granting it
    function grantBadge(uint256 tokenId) external {
        require(tokenId <= tokenIdCounter.current(), "The badge doesn't exist");

        BadgeItem memory badgeItem = tokenIdToBadgeItem[tokenId];

        require(
            badgeItem.level >= 0,
            "The user doesn't has the enought level to have the badge"
        );

        // Add the message caller to the array of token owners
        tokenIdToOwners[tokenId].push(msg.sender);
    }
}
