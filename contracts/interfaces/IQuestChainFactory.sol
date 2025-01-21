// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "./IERC20Token.sol";
import "./IQuestChain.sol";
import "./IQuestChainToken.sol";
import "../libraries/QuestChainCommons.sol";

interface IQuestChainFactory {
    event FactorySetup();
    event QuestChainCreated(uint256 index, address questChain);
    event ShelfCreated(uint256 index, address shelf);
    event AdminReplaceProposed(address proposedAdmin);
    event AdminReplaced(address admin);
    event PaymentTokenReplaceProposed(address proposedPaymentToken);
    event PaymentTokenReplaced(IERC20Token paymentToken);
    event UpgradeFeeReplaceProposed(uint256 proposedUpgradeFee);
    event UpgradeFeeReplaced(uint256 upgradeFee);
    event QuestChainUpgraded(address sender, address questChain);

    function createChain(
        QuestChainCommons.QuestChainInfo calldata _info,
        bytes32 _salt
    ) external returns (IQuestChain);

    // function createAndUpgrade(
    //     QuestChainCommons.QuestChainInfo calldata _info,
    //     bytes32 _salt
    // ) external returns (address);

    // function createAndUpgradeWithPermit(
    //     QuestChainCommons.QuestChainInfo calldata _info,
    //     bytes32 _salt,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external returns (address);

    // function upgradeQuestChain(address _questChainAddress) external;

    // function upgradeQuestChainWithPermit(
    //     address _questChainAddress,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external;

    function getQuestChain(uint256 _index) external view returns (IQuestChain);

    function chainCount() external view returns (uint256);

    function chainTemplate() external view returns (IQuestChain);

    function chainToken() external view returns (IQuestChainToken);

    function admin() external view returns (address);

    // function treasury() external view returns (address);

    // function paymentToken() external view returns (IERC20Token);

    // function upgradeFee() external view returns (uint256);
}
