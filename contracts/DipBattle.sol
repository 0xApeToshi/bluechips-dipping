// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IChipPowers.sol";
import "./IBlueChips.sol";

import "./DAOSafety.sol";

contract DipBattle is DAOSafety {
    // ========== Events ==========
    event BattleStatus(uint256 indexed round, bool indexed status);
    event ChipsUpdate(address indexed newChips);
    event ChipPowersUpdate(address indexed newChipPowers);
    event Scooped(uint256 indexed tokenId, address asset, uint256 amount);

    // ========== Public ==========
    bool public battleStatus;

    address public chips;
    address public chipPowers;

    uint256 public round;

    mapping(uint256 => uint256) public chipsUsedLastRound;

    /**
     * @dev Require battleStatus == true;
     */
    modifier whenBattle() {
        require(battleStatus, "Battle not active!");
        _;
    }

    /**
     * @param _chipPowers Address of ChipPowers.
     * @param _chips Address of Blue Chips (bowl bound).
     */
    constructor(
        address _DAO_MULTISIG,
        address _chipPowers,
        address _chips
    ) DAOSafety(_DAO_MULTISIG) {
        chipPowers = _chipPowers;
        chips = _chips;
    }

    /**
     * @dev Set ChipPowers.
     */
    function configChips(address _chips) external onlyDAO {
        chips = _chips;
        emit ChipsUpdate(_chips);
    }

    /**
     * @dev Set ChipPowers.
     */
    function configChipPowers(address _chipPowers) external onlyDAO {
        chipPowers = chipPowers;
        emit ChipPowersUpdate(_chipPowers);
    }

    /**
     * @dev Move the rounds up. First call starts the game, second one pauses it.
     */
    function progressGame() external whenNotPaused onlyDevs {
        battleStatus = !battleStatus;
        if (battleStatus == true) {
            round++;
        }
        emit BattleStatus(round, battleStatus);
    }

    /**
     * @param assets Token addresses to scoop.
     * @param chipIds Chip tokenId's.
     */
    function scoop(address[] calldata assets, uint256[] calldata chipIds)
        external
        whenNotPaused
        whenBattle
    {
        require(assets.length == chipIds.length, "Incorrect calldata lenght");
        uint256 power;
        uint256 balance;
        for (uint256 i; i < chipIds.length; i++) {
            require(
                IERC721(chips).ownerOf(chipIds[i]) == msg.sender,
                "Chip not owned!"
            );

            require(
                chipsUsedLastRound[chipIds[i]] != round,
                "Chip used this round"
            );
            chipsUsedLastRound[chipIds[i]] = round;

            power = IChipPowers(chipPowers).getPower(chipIds[i]);
            balance = IERC20(assets[i]).balanceOf(address(this));
            if (balance < power) {
                // In case the contract has no more tokens
                power = balance;
            }
            if (power > 0) {
                require(
                    IERC20(assets[i]).transfer(msg.sender, power),
                    "Transfer failed!"
                );
                emit Scooped(chipIds[i], assets[i], power);
            }
        }
    }

    /**
     * @dev Return available (undipped) chips of `owner`.
     */
    function availableTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = IBlueChips(chips).balanceOf(owner);
        uint256[] memory allChips = new uint256[](tokenCount);
        allChips = IBlueChips(chips).tokensOfOwner(owner);
        uint256 unusedCount;
        for (uint256 i; i < allChips.length; i++) {
            if (chipsUsedLastRound[allChips[i]] != round) {
                unusedCount++;
            }
        }

        if (unusedCount == 0) {
            return allChips;
        }
        uint256[] memory unusedChips = new uint256[](unusedCount);
        uint256 k;
        for (uint256 i; i < unusedCount; i++) {
            if (chipsUsedLastRound[allChips[i]] != round) {
                unusedChips[k] = allChips[i];
                k++;
            }
        }
        return unusedChips;
    }

    function withdrawERC20(address asset, uint256 amount) external onlyDAO {
        require(IERC20(asset).transfer(msg.sender, amount), "Transfer failed!");
    }
}
