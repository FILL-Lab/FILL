// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/MinerAPI.sol";
import "@zondax/filecoin-solidity/contracts/v0.8/AccountAPI.sol";

import "./Context.sol";

contract Validation is Context {
    mapping(bytes => uint256) private nonces;

    function validateOwner(
        bytes memory minerAddr,
        bytes memory signature,
        address sender
    ) external {
        bytes memory ownerAddr = getOwner(minerAddr);
        bytes memory digest = getDigest(
            ownerAddr,
            minerAddr,
            sender
        );
        AccountAPI.authenticateMessage(
            ownerAddr,
            AccountTypes.AuthenticateMessageParams({
                signature: signature,
                message: digest
            })
        );
        
        nonces[ownerAddr] += 1;
    }

    function getSigningMsg(bytes memory minerAddr) external returns (bytes memory) {
        bytes memory ownerAddr = getOwner(minerAddr);
        return getDigest(ownerAddr, minerAddr, _msgSender());
    }

    function getDigest(
        bytes memory ownerAddr,
        bytes memory minerAddr,
        address sender
    ) private view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encode(
            keccak256("validateOwner"),
            ownerAddr,
            minerAddr,
            sender,
            nonces[ownerAddr],
            getChainId()
        ));
        return bytes.concat(digest);
    }

    function getOwner(bytes memory minerAddr) private returns (bytes memory) {
        return MinerAPI.getOwner(minerAddr).owner;
    }

    function getChainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}
