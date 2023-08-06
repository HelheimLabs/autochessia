// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

library Random {
    /**
     * not real random but it doesn't matter too much
     */
    function getRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encode(blockhash(block.number - 1), block.number, gasleft())));
    }
}
