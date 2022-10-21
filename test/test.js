const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");

describe("CGG contract", function() {
    //global vars
    let Token;
    let cggToken;
    let admin;
    let addr1;
    let addr2;
    let tokenCap;
});

beforeEach(async function () {
    Token = await ethers.getContractFactory("CGGToken");
    [owner, addr1, addr2] = await hre.ethers.getSigner();

    cggToken = await Token.deploy();
});


describe("Depolyment", function () {
    it("Should set the right admin", async function () {
        expect(await cggToken.admin()).to.equal(admin.address);
    })
});