// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract DAOController {
    address public immutable DAO_MULTISIG;

    constructor(address _DAO_MULTISIG) {
        DAO_MULTISIG = _DAO_MULTISIG;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO_MULTISIG, "Only DAO");
        _;
    }
}
