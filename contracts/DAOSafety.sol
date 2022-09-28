// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./DAOController.sol";

abstract contract DAOSafety is DAOController, Pausable {
    // ========== Events ==========
    event EmergencyTokenTransfer(
        address indexed tokenAddress,
        uint256 indexed amount
    );
    event EmergencyNftTransfer(
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event EmergencyNativeTransfer(uint256 indexed amount);

    event DevsUpdate(address account, bool state);

    // ========== Public variables ==========

    mapping(address => bool) public devsAllowed;

    constructor(address _DAO_MULTISIG) DAOController(_DAO_MULTISIG) {}

    modifier onlyDevs() {
        require(
            msg.sender == DAO_MULTISIG || devsAllowed[msg.sender],
            "Only devs"
        );
        _;
    }

    function configDevs(address account, bool state) external onlyDAO {
        _configDevs(account, state);
    }

    // ========== Make room for potential human errors (made by others) ==========
    function emergencyTokenTransfer(address tokenAddress, uint256 amount)
        external
        onlyDAO
    {
        require(IERC20(tokenAddress).transfer(msg.sender, amount));
        emit EmergencyTokenTransfer(tokenAddress, amount);
    }

    function withdrawNative() external onlyDAO {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unable to withdraw native token");
        emit EmergencyNativeTransfer(amount);
    }

    function withdrawNft(address tokenAddress, uint256 tokenId)
        external
        onlyDAO
    {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        emit EmergencyNftTransfer(tokenAddress, tokenId);
    }

    // ========== Internal ==========

    function _configDevs(address account, bool state) internal {
        devsAllowed[account] = state;
        emit DevsUpdate(account, state);
    }

    // ========== In case of other unforeseen events ==========

    // Dev wallets can hit the brakes faster than a multisig
    function pause() external onlyDevs {
        _pause();
    }

    function unpause() external onlyDAO {
        _unpause();
    }
}
