const fa = require("@glif/filecoin-address");
const { utils } = require("ethers");
const { task } = require("hardhat/config");
const { callRpc, hexToBytes } = require("./common");

task("fill-fillInfo", "fillInfo")
  .addParam("contractaddress", "The FILLContract address")
  .setAction(async (taskArgs) => {
    const contractAddr = taskArgs.contractaddress;
    const FILLContract = await ethers.getContractFactory("FILL");
    //Get signer information
    const accounts = await ethers.getSigners();
    const signer = accounts[0];

    const FILLContractInterface = new ethers.Contract(
      contractAddr,
      FILLContract.interface,
      signer
    );
    const fillInfo = await FILLContractInterface.fillInfo();
    console.log("fillInfo:", fillInfo);
  });
module.exports = {};
