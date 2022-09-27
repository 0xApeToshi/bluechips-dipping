// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBlueChips is IERC721 {
    function tokensOfOwner(address) external view returns (uint256[] memory);
}
