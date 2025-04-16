// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "../interfaces/ILimiter.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import { MultiToken, Category } from "../libraries/MultiToken.sol";

/// @author @parv3213
contract LimiterTokenFee is ILimiter {
    using MultiToken for MultiToken.Asset;

    struct BookDetails {
        address tokenAddress;
        Category category;
        uint256 nftId;
        address treasuryAddress;
        uint256 feeAmount;
    }
    mapping(address => BookDetails) public bookDetails;

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event AddBookDetails(
        address _book,
        address _tokenAddress,
        address _treasuryAddress,
        uint256 _feeAmount,
        address _sender
    );

    function addBookDetails(
        address _book,
        address _tokenAddress,
        Category _category,
        uint256 _nftId,
        address _treasuryAddress,
        uint256 _feeAmount
    ) external {
        require(
            IAccessControl(_book).hasRole(ADMIN_ROLE, msg.sender),
            "TokenGated: only admin"
        );
        bookDetails[_book] = BookDetails(
            _tokenAddress,
            _category,
            _nftId,
            _treasuryAddress,
            _feeAmount
        );
        emit AddBookDetails(
            _book,
            _tokenAddress,
            _treasuryAddress,
            _feeAmount,
            msg.sender
        );
    }

    function submitProofLimiter(
        address _sender,
        uint256[] calldata /* _bookIdList */
    ) external {
        BookDetails memory _details = bookDetails[msg.sender];

        MultiToken
            .Asset(
                _details.tokenAddress,
                _details.category,
                _details.feeAmount,
                _details.nftId
            )
            .transferAssetFrom(_sender, _details.treasuryAddress);
    }
}
