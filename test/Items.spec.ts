import { ethers } from "hardhat";
import { Contract } from "ethers";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

function isEthereumAddress(address: string) {
    if (!address.matchAll(/^(0x)?[0-9a-fA-F]{40}$/g)) return false;
    return true;
}

interface Item {
    name: string;
    description: string;
    pictureURL: string;
    metadataURL: string;
}

describe("Deploy and test the Items smart contract", () => {
    let contract: Contract;
    let owner: SignerWithAddress;
    let itemData: Item;

    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        const contractFactory = await ethers.getContractFactory("Items");

        contract = await contractFactory.connect(owner).deploy("Test", "TEST");

        await contract.deployed();

        itemData = {
            name: "Dropbot",
            description: "The Dropbot is an agent cappable of ...",
            pictureURL: "https://dropbot.com/public/imagesdropbot.png",
            metadataURL: "https://dropbot.com/public/metadata/dropbot.json",
        }
    });

    it("Contract address must be defined", async () => {
        expect(contract.address).not.to.be.empty;
    });

    it("Contract address and owner address must be valid", async () => {
        expect(isEthereumAddress(contract.address)).to.be.true;
        expect(isEthereumAddress(owner.address)).to.be.true;
    });
    
    describe("Interact with an item", () => {
        it("Should create a new item", async () => {
            const tx = await contract.connect(owner).addItem(
                itemData.name,
                itemData.description,
                itemData.pictureURL,
                itemData.metadataURL,
            );

            expect(tx).to.be.an("object");
            expect(tx).to.have.property("hash");

            const _itemData = await contract.itemIdToItem(1);  

            expect(_itemData).to.have.lengthOf(4);

            expect(_itemData[0]).to.equal(itemData.name);
            expect(_itemData[1]).to.equal(itemData.description);
            expect(_itemData[2]).to.equal(itemData.pictureURL);
            expect(_itemData[3]).to.equal(itemData.metadataURL);
        });
    })
});