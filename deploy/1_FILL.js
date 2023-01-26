require("hardhat-deploy");
require("hardhat-deploy-ethers");

const ethers = require("ethers");
const fa = require("@glif/filecoin-address");
const util = require("util");
const request = util.promisify(require("request"));

const DEPLOYER_PRIVATE_KEY = network.config.accounts[0];

function hexToBytes(hex) {
  for (var bytes = [], c = 0; c < hex.length; c += 2)
    bytes.push(parseInt(hex.substr(c, 2), 16));
  return new Uint8Array(bytes);
}

async function callRpc(method, params) {
  var options = {
    method: "POST",
    url: network.config.url,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: 1,
    }),
  };
  const res = await request(options);
  return JSON.parse(res.body).result;
}

const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY);

module.exports = async ({ deployments }) => {
  const { deploy } = deployments;

  const priorityFee = await callRpc("eth_maxPriorityFeePerGas");
  const f4Address = fa.newDelegatedEthAddress(deployer.address).toString();
  const deployLogError = async (title, obj) => {
    let ret;
    try {
      ret = await deploy(title, obj);
    } catch (error) {
      console.log(error.toString());
      process.exit(1);
    }
    return ret;
  };

  console.log("Wallet Ethereum Address:", deployer.address);
  console.log("Wallet f4Address: ", f4Address);
  const chainId = network.config.chainId;
  const tokenFLEAddr = "YOUR_FLE_TOKEN_ADDR";
  console.log("deploying FILL");

  await deployLogError("FILL", {
    from: deployer.address,
    args: [tokenFLEAddr],
    maxPriorityFeePerGas: priorityFee,
    log: true,
  });
};

module.exports.tags = ["FILL"];
module.exports.dependencies = ["FLE"];
