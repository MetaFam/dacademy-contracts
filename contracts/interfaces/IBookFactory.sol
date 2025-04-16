// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "./IERC20Token.sol";
import "./IBook.sol";
import "./ICollection.sol";
import "./IShelf.sol";
import "./IBookToken.sol";
import "../libraries/BookCommons.sol";

interface IBookFactory {
    event FactorySetup();
    event BookCreated(uint256 index, address book);
    event ShelfCreated(
        address[] admins, IShelf shelf, uint256 tokenId
    );
    event CollectionCreated(
        address[] admins, ICollection collection
    );
    event AdminReplaceProposed(address proposedAdmin);
    event AdminReplaced(address admin);
    event PaymentTokenReplaceProposed(address proposedPaymentToken);
    event PaymentTokenReplaced(IERC20Token paymentToken);
    event UpgradeFeeReplaceProposed(uint256 proposedUpgradeFee);
    event UpgradeFeeReplaced(uint256 upgradeFee);
    event BookUpgraded(address sender, address book);

    function createBook(
        BookCommons.BookInfo calldata _info,
        bytes32 _salt
    ) external returns (IBook);
    function createShelf(
        IShelf.ShelfInfo calldata _info,
        bytes32 _salt
    ) external returns (IShelf);
    function createCollection(
        ICollection.CollectionInfo calldata _info,
        bytes32 _salt
    ) external returns (ICollection);

    // function createAndUpgrade(
    //     BookCommons.BookInfo calldata _info,
    //     bytes32 _salt
    // ) external returns (address);

    // function createAndUpgradeWithPermit(
    //     BookCommons.BookInfo calldata _info,
    //     bytes32 _salt,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external returns (address);

    // function upgradeBook(address _bookAddress) external;

    // function upgradeBookWithPermit(
    //     address _bookAddress,
    //     uint256 _deadline,
    //     bytes calldata _signature
    // ) external;

    function getBook(uint256 _index) external view returns (IBook);

    function bookCount() external view returns (uint256);

    function tokenCount() external view returns (uint256);

    function bookTemplate() external view returns (IBook);

    function shelfTemplate() external view returns (IShelf);

    function collectionTemplate() external view returns (ICollection);

    function bookToken() external view returns (IBookToken);

    function admin() external view returns (address);

    // function treasury() external view returns (address);

    // function paymentToken() external view returns (IERC20Token);

    // function upgradeFee() external view returns (uint256);
}
