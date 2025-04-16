// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILimiter.sol";
import "../interfaces/IBook.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import {MultiToken, Category} from "../libraries/MultiToken.sol";

/// @author @parv3213
contract LimiterTokenGated is ILimiter {
    using MultiToken for MultiToken.Asset;

    struct BookDetails {
        address tokenAddress;
        Category category;
        uint256 nftId;
        uint256 minTokenBalance;
    }
    mapping(address => BookDetails) public bookDetails;

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event AddBookDetails(
        address _book,
        address _tokenAddress,
        uint256 _minBalance,
        address _sender
    );

    function addBookDetails(
        address _book,
        address _tokenAddress,
        Category _category,
        uint256 _nftId,
        uint256 _minBalance
    ) external {
        require(
            IAccessControl(_book).hasRole(ADMIN_ROLE, msg.sender),
            "TokenGated: only admin"
        );
        bookDetails[_book] = BookDetails(
            _tokenAddress,
            _category,
            _nftId,
            _minBalance
        );
        emit AddBookDetails(
            _book,
            _tokenAddress,
            _minBalance,
            msg.sender
        );
    }

    function submitProofLimiter(
        address _sender,
        uint256[] calldata /* _bookIdList */
    ) external view {
        BookDetails memory _details = bookDetails[msg.sender];

        require(
            MultiToken
                .Asset(
                    _details.tokenAddress,
                    _details.category,
                    0,
                    _details.nftId
                )
                .balanceOf(_sender) >= _details.minTokenBalance,
            "LimiterTokenGated: limited"
        );
    }
}
