// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Collectible1155 is ERC1155, Ownable, ERC1155Supply {
    uint256 public collectibleTypes;
    uint256 public maxSupply;
    uint256 public mintPrice;

    constructor(
        string memory _baseUrl,
        uint256 _collectibleTypes,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) ERC1155(_baseUrl) {
        collectibleTypes = _collectibleTypes;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
    }

    function uri(
        uint256 _id
    ) public view virtual override returns (string memory) {
        require(exists(_id), "Invalid collectible type");
        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount) public payable {
        require(id <= collectibleTypes, "The collectible id is not valid");
        require(
            totalSupply(id) + amount <= maxSupply,
            "The collectible is sold out"
        );
        require(msg.value >= amount * mintPrice, "You don't have enough funds");
        _mint(account, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }
}
