// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/AccountAPI.sol";

contract Validation {
    mapping(bytes => uint256) private nonces;

    function validateOwner(
        bytes memory owner,
        bytes memory signature,
        bytes memory minerAddr,
        address sender,
        uint256 deadline
    ) external {
        bytes memory currentOwner = getOwner(minerAddr);
        require(keccak256(abi.encode(owner)) == keccak256(abi.encode(currentOwner)), "not the owner");
        require(block.timestamp < deadline, "signed transaction expired");
        bytes memory digest = getDigest(
            owner,
            minerAddr,
            sender,
            deadline
        );
        AccountAPI.authenticateMessage(
            owner,
            AccountTypes.AuthenticateMessageParams({
                signature: signature,
                message: digest
            })
        );
        
        nonces[owner] += 1;
    }

    function getOwner(bytes memory minerAddr) public returns (bytes memory) {
        return MinerAPI.getOwner(minerAddr).owner;
    }

    function getDigest(
        bytes memory owner,
        bytes memory minerAddr,
        address sender,
        uint256 deadline
    ) public view returns (bytes memory) {
        bytes32 proto = keccak256(abi.encode(
            keccak256("validateOwner"),
            owner,
            minerAddr,
            sender,
            nonces[owner],
            getChainId(),
            deadline
        ));
        bytes memory digest = new bytes(proto.length);
        for (uint i = 0; i< proto.length; i++){
            digest[i] = proto[i];
        }
        return digest;
    }

    function getChainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}