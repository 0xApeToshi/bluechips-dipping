const Migrations = artifacts.require("Migrations");
const ChipPowersV1 = artifacts.require("ChipPowersV1");
const DipBattle = artifacts.require("DipBattle");

module.exports = function (deployer) {
    deployer.deploy(Migrations);
    deployer.deploy(ChipPowersV1);
    deployer.deploy(DipBattle, Chi);
};

module.exports = function (deployer, network, accounts) {
    deployer.then(async () => {
        await deployer.deploy(Migrations);
        const chipPowersV1 = await deployer.deploy(ChipPowersV1);
        const dipBattle = await deployer.deploy(DipBattle, accounts[0], chipPowersV1.address, chipPowersV1.address);
    });
};