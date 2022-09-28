// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IChipPowers.sol";
import "./IBlueChips.sol";

import "./DAOSafety.sol";

contract DipBattle is DAOSafety {
    // ========== Events ==========
    event BattleStatus(uint256 indexed round, bool indexed status);
    event DipsUpdate(uint256 indexed newId, address indexed newDip);
    event ChipsUpdate(address indexed newChips);
    event ChipPowersUpdate(address indexed newChipPowers);
    event Scooped(uint256 indexed tokenId, address asset, uint256 amount);

    // ========== Public ==========
    bool public battleStatus;

    address public chips;
    address public chipPowers;

    uint256 public round;

    mapping(uint256 => address) public dips;
    mapping(uint256 => uint256) public chipLastRound;

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

        // WGUAC
        _configDipId(0, 0xaedc0DDeEF17Ce79DaaA800e434bd49679F9d4F8);
        // WSALAS
        _configDipId(1, 0x4E16ce724dE731b3Aaf794De9f9673F0EFF2CB42);
        // WQUESO
        _configDipId(2, 0x87475d320368B578Bf365DF21E7FecF590146F2e);
    }

    function configDipId(uint256 id, address dip) external onlyDAO {
        _configDipId(id, dip);
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
        chipPowers = _chipPowers;
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
     * @param dipIds Token addresses to scoop.
     * @param chipIds Chip tokenId's.
     */
    function scoop(uint256[] calldata dipIds, uint256[] calldata chipIds)
        external
        whenNotPaused
        whenBattle
    {
        require(dipIds.length == chipIds.length, "Incorrect calldata lenght");
        uint256 chip;
        uint256 power;
        uint256 balance;
        uint256 dipId;
        address dip;
        for (uint256 i; i < chipIds.length; ) {
            chip = chipIds[i];
            require(
                IERC721(chips).ownerOf(chip) == msg.sender,
                "Chip not owned!"
            );

            require(chipLastRound[chip] != round, "Chip used this round");
            chipLastRound[chip] = round;

            dipId = dipIds[i];
            dip = dips[dipId];

            require(dip != address(0), "Invalid dip");

            power = IChipPowers(chipPowers).getPower(chip);
            balance = IERC20(dip).balanceOf(address(this));
            if (balance < power) {
                // In case the contract has no more tokens
                power = balance;
            }
            if (power > 0) {
                require(
                    IERC20(dip).transfer(msg.sender, power),
                    "Transfer failed!"
                );
                emit Scooped(chip, dip, power);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Return available (undipped) chips of `owner`. First tokenId needs to start from 1.
     */
    function availableTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokensOfOwner = IBlueChips(chips).tokensOfOwner(owner);
        // TEST
        uint256 unusedCount;

        uint256 tokenId;
        for (uint256 i; i < tokensOfOwner.length; i++) {
            tokenId = tokensOfOwner[i];

            if (chipLastRound[tokenId] < round) {
                unusedCount++;
            }
        }

        if (unusedCount == 0) {
            return tokensOfOwner;
        }

        uint256[] memory unusedTokensOfOwner = new uint256[](unusedCount);
        uint256 k;
        for (uint256 i; i < tokensOfOwner.length; ) {
            tokenId = tokensOfOwner[i];
            if (chipLastRound[tokenId] < round) {
                unusedTokensOfOwner[k] = tokenId;
                unchecked {
                    k++;
                }
            }
            unchecked {
                i++;
            }
        }
        return unusedTokensOfOwner;
    }

    function withdrawERC20(address asset, uint256 amount) external onlyDAO {
        require(IERC20(asset).transfer(msg.sender, amount), "Transfer failed!");
    }

    // ========== Internal functions ==========

    function _configDipId(uint256 id, address dip) internal {
        dips[id] = dip;
        emit DipsUpdate(id, dip);
    }
}
