// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChipPowers {
    function getPower(uint256 tokenId) external returns (uint256);
}
