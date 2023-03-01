// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@zondax/filecoin-solidity/contracts/v0.8/types/CommonTypes.sol";

library Convertion {
    function bigInt2Uint(CommonTypes.BigInt memory num) internal pure returns (uint) {
        assert(!num.neg);
        assert(num.val.length <= 32);
        if (num.val.length == 0) {
            return 0;
        }
        return uint(bytes32(num.val)) >> (8 * (32 - num.val.length));
    }

    function uint2BigInt(uint num) internal pure returns (CommonTypes.BigInt memory) {
        return CommonTypes.BigInt({
            val: abi.encodePacked(num),
            neg: false
        });
    }
}
