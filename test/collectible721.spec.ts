import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { PromiseOrValue } from "../typechain-types/common";

const publicMintStartDate = new Date();
publicMintStartDate.setMinutes(publicMintStartDate.getMinutes() + 10);

interface ContractDeployData {
    name: string;
    symbol: string;
    baseUri: string;
    collectiblePrices: [PromiseOrValue<string>, PromiseOrValue<string>];
    preMintDates: [PromiseOrValue<number>, PromiseOrValue<number>];
    maxMintCollectiblesPerWallet: [PromiseOrValue<number>, PromiseOrValue<number>];
    maxPreMintCollectibles: number,
    maxSupply: number;
    publicMintStartDate: number;
};

const contractData: ContractDeployData = {
    name: "The Fight Club",
    symbol: "TFCB",
    baseUri: "ipfs://QmYmQ6L2i3WxQ5Zk2LhNX7fDgJYgRy3XTDHWdqRkzVX7dF/",
    collectiblePrices: [
        ethers.utils.parseEther("0").toString(),
        ethers.utils.parseEther("0.05").toString(),
    ],
    preMintDates: [0, 0],
    maxMintCollectiblesPerWallet: [5, 5],
    maxPreMintCollectibles: 8,
    maxSupply: 20,
    publicMintStartDate: Math.floor(publicMintStartDate.getTime() / 1000),
}


describe("Collectible721 testing", () => {
    async function deployContractFixture() {


        const [owner, addr1, ...addrs] = await ethers.getSigners();

        const Collectible721 = await ethers.getContractFactory("Collectible721");

        const contract = await Collectible721.connect(owner).deploy(
            contractData.name,
            contractData.symbol,
            contractData.baseUri,
            contractData.collectiblePrices,
            contractData.preMintDates,
            contractData.maxMintCollectiblesPerWallet,
            contractData.maxPreMintCollectibles,
            contractData.maxSupply,
            contractData.publicMintStartDate,
        );

        await contract.deployed();

        return {
            contract,
            owner,
            addr1,
            addrs,
        }
    }

    async function forwardTimeFixture() {
        const latestBlockNumber = await ethers.provider.getBlockNumber();
        const latestBlock = await ethers.provider.getBlock(latestBlockNumber);

        await ethers.provider.send("evm_setNextBlockTimestamp", [latestBlock.timestamp + 3600]);
        await ethers.provider.send("evm_mine", []);
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

        it("Should verify all the deployed smart initial state match the deployed one", async () => {
            const { contract } = await loadFixture(deployContractFixture);

            // Pre-mint data
            await expect(contract.maxPreMintCollectibles()).to.eventually.equal(contractData.maxPreMintCollectibles);
            await expect(contract.maxPreMintCollectiblesPerWallet()).to.eventually.equal(contractData.maxMintCollectiblesPerWallet[0]);
            await expect(contract.preMintStartDate()).to.eventually.equal(contractData.preMintDates[0]);
            await expect(contract.preMintEndDate()).to.eventually.equal(contractData.preMintDates[1]);
            await expect(contract.preMintPrice()).to.eventually.equal(contractData.collectiblePrices[0]);

            // Public mint data
            await expect(contract.publicMintPrice()).to.eventually.equal(contractData.collectiblePrices[1]);
            await expect(contract.publicMintStartDate()).to.eventually.equal(contractData.publicMintStartDate);``
            await expect(contract.totalSupply()).to.eventually.equal(0);

        });

        it("Should fail to pre-mint since the contract doesn't allows it", async () => {
            const { contract } = await loadFixture(deployContractFixture);

            await expect(contract.premint(1))
                .to
                .be
                .revertedWith("Premint is not enabled for this collectible");
        });

        it("Should fail to mint before the public mint date", async () => {
            const { contract } = await loadFixture(deployContractFixture);

            await expect(contract.publicMint(1))
                .to
                .be
                .revertedWith("The collectibles are not available for public sale for now");
        });

        it("Should do the public mint after the public mint date has passed", async () => {
            const { contract, owner } = await loadFixture(deployContractFixture);
            await loadFixture(forwardTimeFixture);

            const tx = await contract.publicMint(2, {
                value: ethers.utils.parseEther("0.1"),
            });

            expect(tx).to.not.be.undefined;

            // The total supply must be of one item for now
            await expect(contract.totalSupply()).to.eventually.equal(2);

            // The balance of the owner must be of one token
            await expect(contract.balanceOf(owner.address)).to.eventually.equal(2);

            // The token with id 1 must belong to the owner
            await expect(contract.ownerOf(2)).to.eventually.equal(owner.address);

            // The token URI must match the expect format (with json extension)
            await expect(contract.tokenURI(2)).to.eventually.equal(contractData.baseUri + "2.json");
        });

        it("Shouldn't enable the public when the user has not enough funds", async () => {
            const { contract } = await loadFixture(deployContractFixture);
            await loadFixture(forwardTimeFixture);

            await expect(contract.publicMint(2, {
                value: ethers.utils.parseEther("0.05")
            })).to.be.revertedWith("Not enough funds");
        });

        it("Shouldn't enable an user to mint more than 5 colletibles", async () => {
            const { contract } = await loadFixture(deployContractFixture);
            await loadFixture(forwardTimeFixture);
            
            await expect(contract.publicMint(6, {
                value: ethers.utils.parseEther("0.4"),
            })).to.revertedWith("Maximum collectibles per wallet minted");
        });

        it("Should fail to mint more than the maximum supplied collectibles", async () => {
            const { contract, owner, addr1, addrs } = await loadFixture(deployContractFixture);
            await loadFixture(forwardTimeFixture);

            await contract.connect(owner).publicMint(5, {
                value: ethers.utils.parseEther("2.5"),
            });

            await contract.connect(addr1).publicMint(5, {
                value: ethers.utils.parseEther("2.5"),
            });

            await contract.connect(addrs[0]).publicMint(5, {
                value: ethers.utils.parseEther("2.5"),
            });

            await contract.connect(addrs[1]).publicMint(5, {
                value: ethers.utils.parseEther("2.5"),
            });

            await expect(contract.totalSupply()).to.eventually.equal(20);

            await expect(ethers.provider.getBalance(contract.address)).to.eventually.equal(
                ethers.utils.parseEther(`${20 * 0.5}`),
            );

            await expect(contract.withdraw(owner.address)
                .then(() => 
                    ethers.provider.getBalance(contract.address)
                )
                .then((contractBalance) => contractBalance)
            ).to.eventually.equal(ethers.utils.parseEther("0"));

            await expect(contract.connect(addrs[2]).publicMint(1, {
                value: ethers.utils.parseEther("0.05"),
            })).to.be.revertedWith("Sold Out");
        });
    });
});
