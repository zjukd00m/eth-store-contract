import { ethers } from "hardhat";
import { Contract, Transaction } from "ethers";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

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
    let itemData: Item;
    let itemEditData: Item;

    // Fixture function is executed only once when testing
    async function deployItemsFixture() {
        const [owner, addr1] = await ethers.getSigners();

        const contractFactory = await ethers.getContractFactory("Items");
        
        const contract: Contract = await contractFactory.deploy("test", "TEST");

        await contract.deployed();

        return {contract, owner, addr1}
    }

    async function createItemFixture() {
        const { contract, owner } = await loadFixture(deployItemsFixture)

        const tx: Transaction = await contract
            .connect(owner)
            .addItem(
                itemData.name,
                itemData.description,
                itemData.pictureURL,
                itemData.metadataURL,
            );

        return { tx };
    }

    beforeEach(() => {
        itemData = {
            name: "Dropbot",
            description: "The Dropbot is an agent cappable of ...",
            pictureURL: "https://dropbot.com/public/imagesdropbot.png",
            metadataURL: "https://dropbot.com/public/metadata/dropbot.json",
        }

        itemEditData = {
            name: "Dr0pb0t",
            description: "The Dr0pb0t was here!",
            pictureURL: "https://dropbot.com/public/images/dr0pb0t.png",
            metadataURL: "https://dropbot.com/public/metadata/dr0pb0t.json",
        }
    });


    it("Contract address and user addresses must be defined", async () => {
        const { contract, owner } = await loadFixture(deployItemsFixture)

        expect(contract?.address).not.to.be.empty;
        expect(owner?.address).not.to.be.empty;
    });

    it("Contract address and owner address must be valid", async () => {
        const { contract, owner, addr1 } = await loadFixture(deployItemsFixture);

        expect(isEthereumAddress(contract.address)).to.be.true;
        expect(isEthereumAddress(owner.address)).to.be.true;
        expect(isEthereumAddress(addr1.address)).to.be.true;
    });
    
    describe("Interact with an item", () => {
        it("Should create a new item", async () => {
            const { contract } = await loadFixture(deployItemsFixture);
            const { tx } = await loadFixture(createItemFixture);

            expect(tx).to.be.an("object");
            expect(tx).to.have.property("hash");

            const _itemData = await contract.itemIdToItem(1);  

            expect(_itemData).to.have.lengthOf(4);

            expect(_itemData[0]).to.equal(itemData.name);
            expect(_itemData[1]).to.equal(itemData.description);
            expect(_itemData[2]).to.equal(itemData.pictureURL);
            expect(_itemData[3]).to.equal(itemData.metadataURL);
        });

        it("Shouldn't let the non owner account to create an item", async () => {
            const { contract, addr1 } = await loadFixture(deployItemsFixture);

            await expect(contract.connect(addr1).addItem(
                itemData.name,
                itemData.description,
                itemData.pictureURL,
                itemData.metadataURL,
            )).to.be.revertedWith("Ownable: caller is not the owner");
        });
            
        it("Should let the owner edit the inserted item's data", async () => {
            const { contract, owner } = await loadFixture(deployItemsFixture);
            await loadFixture(createItemFixture);

            await contract
                .connect(owner)
                .editItem(
                    1,
                    itemEditData.name,
                    itemEditData.description,
                    itemEditData.pictureURL,
                    itemEditData.metadataURL,
                );

            const _itemData = await contract.itemIdToItem(1);
            
            expect(_itemData).to.have.lengthOf(4);
            expect(_itemData[0]).to.equal(itemEditData.name);
            expect(_itemData[1]).to.equal(itemEditData.description);
            expect(_itemData[2]).to.equal(itemEditData.pictureURL);
            expect(_itemData[3]).to.equal(itemEditData.metadataURL);
        });

        it("Shouldn't let the non owner account to edit an item", async () => {
            const { contract, addr1 } = await loadFixture(deployItemsFixture);
            await loadFixture(createItemFixture);

            await expect(contract.connect(addr1).editItem(
                1,
                itemEditData.name,
                itemEditData.description,
                itemEditData.pictureURL,
                itemEditData.metadataURL,
            )).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should change the smart contract's name and symbol", async () => {
            const { contract, owner } = await loadFixture(deployItemsFixture);

            await contract.connect(owner).changeName("test 2");
            await contract.connect(owner).changeSymbol("TST2");

            expect(await contract.name()).to.equal("test 2");
            expect(await contract.symbol()).to.equal("TST2");
        });

        it("Shouldn't let the non owner account to change the smart contract's name", async () => {
            const { contract, addr1 } = await loadFixture(deployItemsFixture);

            await expect(contract
                .connect(addr1)
                .changeName("test 2")
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    })
});