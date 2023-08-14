import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

const publicMintStartDate = new Date();
publicMintStartDate.setMinutes(publicMintStartDate.getMinutes() + 10);

describe("Collectible721 testing", () => {
    async function deployContractFixture() {

        const contractData = {
            collectibleName: "Fight Club",
            collectibleSymbol: "FCUB",
            baseUri: "ipfs://QmYmQ6L2i3WxQ5Zk2LhNX7fDgJYgRy3XTDHWdqRkzVX7dF/",
            maxSupply: 10,
            preMintPrice: 0,
            preMintStartDate: 0,
            preMintEndDate: 0,
            maxPreMintCollectibles: 0,
            maxPreMintCollectiblesPerWallet: 0,
            publicMintPrice: BigInt("500000000000000000"),
            publicMintStartDate: Math.floor(publicMintStartDate.getTime() / 1000),
        }

        const [owner, addr1] = await ethers.getSigners();

        const Collectible721 = await ethers.getContractFactory("Collectible721");

        const contract = await Collectible721.connect(owner).deploy(
            contractData.collectibleName,
            contractData.collectibleSymbol,
            contractData.baseUri,
            contractData.maxSupply,
            contractData.preMintPrice,
            contractData.preMintStartDate,
            contractData.preMintEndDate,
            contractData.maxPreMintCollectibles,
            contractData.maxPreMintCollectiblesPerWallet,
            contractData.publicMintPrice,
            contractData.publicMintStartDate,
        );

        await contract.deployed();

        return {
            contract,
            owner,
            addr1
        }
    }

    describe("Testing the smart contract", () => {
        it("Should deploy the contract and be a valid address", async () => {
            const { contract, owner, addr1 } = await loadFixture(deployContractFixture);

            expect(contract.address).not.to.be.undefined;
            expect(owner.address).not.to.be.undefined;
            expect(addr1.address).not.to.be.undefined;

            expect(contract.address).to.have.length;
            expect(owner.address).to.have.length;
            expect(addr1.address).to.have.length;
        })
    })
})