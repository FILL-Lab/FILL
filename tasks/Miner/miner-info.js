/*******************************************************************************
 *   (c) 2022 Zondax AG
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ********************************************************************************/
//
// DRAFT!! THIS CODE HAS NOT BEEN AUDITED - USE ONLY FOR PROTOTYPING
//
const fa = require("@glif/filecoin-address");
const { callRpc } = require("../common");

task("miner-info", "")
  .addParam("contractaddress", "The MinerOp address")
  .setAction(async (taskArgs) => {
    const contractAddr = taskArgs.contractaddress;
    const { beneficiary, quota, expiration } = taskArgs;
    const networkId = network.name;

    const priorityFee = await callRpc(
      network.config.url,
      "eth_maxPriorityFeePerGas"
    );

    console.log("Calling getBeneficiary method");
    const MinerOp = await ethers.getContractFactory("MinerOp");

    //Get signer information
    const accounts = await ethers.getSigners();
    const signer = accounts[0];

    const minerAPIContract = new ethers.Contract(
      contractAddr,
      MinerOp.interface,
      signer
    );
    const minerId = fa.newFromString("t01000");
    console.log(
      "minerId :",
      minerId.toString(),
      ",bytes: ",
      minerId.bytes,
      "hex addr:",
      Buffer.from(minerId.bytes).toString("hex")
    );
    const ret = await minerAPIContract.get_beneficiary(minerId.bytes, {
      gasLimit: 1000000000,
      maxPriorityFeePerGas: priorityFee,
    });
    console.log("ret:", await ret.wait());
  });

module.exports = {};
