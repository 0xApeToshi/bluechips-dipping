// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChipPowers.sol";

contract ChipPowersV1 is IChipPowers {
    function getPower(uint256 tokenId) external pure returns (uint256) {
        if (tokenId % 12 == 0) {
            return 1275 * 10**18;
        }
        return 1020 * 10**18;
    }
}
