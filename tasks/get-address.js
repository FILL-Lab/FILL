const fa = require("@glif/filecoin-address");
const { utils } = require("ethers");
const { callRpc, hexToBytes } = require("./common");

task(
  "get-address",
  "Gets Filecoin f4 address and corresponding Ethereum address."
).setAction(async (taskArgs) => {
  const DEPLOYER_PRIVATE_KEY = network.config.accounts[0];

  const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY);

  const pubKey = hexToBytes(deployer.publicKey.slice(2));

  const priorityFee = await callRpc(
    network.config.url,
    "eth_maxPriorityFeePerGas"
  );
  console.log(priorityFee);

  const minerId = fa.newFromString("t01000");
  console.log(
    "minerId :",
    minerId.toString(),
    ",payload: ",
    minerId.payload(),
    "hex addr:",
    Buffer.from(minerId.bytes).toString("hex"),
    utils.hexlify(minerId.bytes)
  );

  const addrHex = "0x00e807";
  const newAddr = fa.newAddress(
    0,
    utils.arrayify(utils.hexStripZeros(addrHex))
  );
  console.log(newAddr.toString());
  // console.log(fa.idFromAddress(newAddr));
  const filBalance = await callRpc(
    network.config.url,
    "Filecoin.WalletBalance",
    [newAddr.toString()]
  );
  console.log("filBalance:", filBalance);

  const f4Address = fa.newDelegatedEthAddress(deployer.address).toString();
  const nonce = await callRpc(network.config.url, "Filecoin.MpoolGetNonce", [
    f4Address,
  ]);
  console.log(
    "Ethereum address (this addresss should work for most tools):",
    deployer.address
  );
  console.log("f4address (informational only):", f4Address);
});

module.exports = {};
