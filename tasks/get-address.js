const fa = require("@glif/filecoin-address");
const util = require("util");
const request = util.promisify(require("request"));
const { utils } = require("ethers");

task(
  "get-address",
  "Gets Filecoin f4 address and corresponding Ethereum address."
).setAction(async (taskArgs) => {
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

  const pubKey = hexToBytes(deployer.publicKey.slice(2));

  const priorityFee = await callRpc("eth_maxPriorityFeePerGas");

  const minerId = fa.newFromString("t01000");
  console.log(
    "minerId :",
    minerId.toString(),
    ",bytes: ",
    minerId.bytes,
    "hex addr:",
    Buffer.from(minerId.bytes).toString("hex"),
    utils.hexlify(minerId.bytes)
  );

  const f4Address = fa.newDelegatedEthAddress(deployer.address).toString();
  const nonce = await callRpc("Filecoin.MpoolGetNonce", [f4Address]);
  console.log(
    "Ethereum address (this addresss should work for most tools):",
    deployer.address
  );
  console.log("f4address (informational only):", f4Address);
});

module.exports = {};
