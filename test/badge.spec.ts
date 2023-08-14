import { ethers } from "hardhat";
import { expect } from "chai"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
 

describe("Badge smart contract is tested", () => {
    async function deployBadgeFixture() {
        const [owner, addr1] = await ethers.getSigners();
        const Badge = await ethers.getContractFactory("Badge");
        const badge = await Badge.deploy();

        await badge.deployed();

        return { badge, owner, addr1 };
    }

    describe("Test it all", () => {
        it("Should deploy Badge smart contract", async () => {
            const { badge, owner, addr1 } = await loadFixture(deployBadgeFixture);

            expect(badge.address).not.to.be.undefined;
            expect(await owner.getAddress()).to.have.length;
            expect(await addr1.getAddress()).to.have.length;
        })
    })
});