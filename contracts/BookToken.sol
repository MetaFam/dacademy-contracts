// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

//   ╔═╗ ┬ ┬┌─┐┌─┐┌┬┐╔═╗┬ ┬┌─┐┬┌┐┌┌─┐
//   ║═╬╗│ │├┤ └─┐ │ ║  ├─┤├─┤││││└─┐
//   ╚═╝╚└─┘└─┘└─┘ ┴ ╚═╝┴ ┴┴ ┴┴┘└┘└─┘

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IBook.sol";
import "./interfaces/IBookToken.sol";

// author: @dan13ram

contract BookToken is IBookToken, ERC1155 {
    IBookFactory public immutable factory;

    string public name = "dAcademy Achievement";
    string public symbol = "DAA";

    mapping(uint256 => string) private _uris;
    mapping(uint256 => address) private _owners;

    /**
     * @dev Access control modifier for functions callable by factory contract only
     */
    modifier onlyFactory() {
        require(msg.sender == address(factory), "BookToken: not factory");
        _;
    }

    /**
     * @dev Access control modifier for functions callable by token owners only
     * @param _id the complete initialization data
     */
    modifier onlyTokenOwner(uint256 _id) {
        require(msg.sender == _owners[_id], "BookToken: not token owner");
        _;
    }

    constructor() ERC1155("") {
        factory = IBookFactory(_msgSender());
    }

    /*************************
     * ACCESS CONTROL FUNCTIONS
     *************************/

    /**
     * @dev Assigns book ownership
     * @param _id the book NFT identifier
     * @param _book the address of the new Book minimal proxy
     */
    function setTokenOwner(uint256 _id, address _book) public onlyFactory {
        _owners[_id] = _book;
    }

    /**
     * @dev Assigns the metadata location for a book token
     * @param _id the book NFT identifier
     * @param _uri the URI for the token metadata
     */
    function setTokenURI(
        uint256 _id,
        string memory _uri
    ) public onlyTokenOwner(_id) {
        _uris[_id] = _uri;

        emit URI(_uri, _id);
    }

    /**
     * @dev Mints a book achievement token to the user
     * @param _user the address of a successful user
     * @param _id the book token identifier
     */
    function mint(address _user, uint256 _id) public onlyTokenOwner(_id) {
        require(balanceOf(_user, _id) == 0, "BookToken: already minted");

        _mint(_user, _id, 1, "");
    }

    /**
     * @dev Burns a book achievement token from the user
     * @param _user the address of an owning user
     * @param _id the book token identifier
     */
    function burn(address _user, uint256 _id) public onlyTokenOwner(_id) {
        uint256 balance = balanceOf(_user, _id);

        require(balance > 0, "BookToken: token not found");

        _burn(_user, _id, balance);
    }

    /*************************
     * VIEW AND PURE FUNCTIONS
     *************************/

    /**
     * @return Owner address of a book token
     * @param _id the book token identifier
     */
    function tokenOwner(uint256 _id) public view returns (address) {
        return _owners[_id];
    }

    /**
     * @return Metadata URI of a particular book token
     * @param _id the book token identifier
     */
    function uri(
        uint256 _id
    )
        public
        view
        override(IERC1155MetadataURI, ERC1155)
        returns (string memory)
    {
        return _uris[_id];
    }

    /*************************
     * OVERRIDES
     *************************/

    /**
     * @dev Prevents transferring the tokens and thus makes them SoulBound
     */
    function _beforeTokenTransfer(
        address,
        address _from,
        address _to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal pure override {
        require(
            _to == address(0) || _from == address(0),
            "BookToken: soulbound"
        );
    }

    /**
     * @dev Prevents approval of the tokens and thus makes them SoulBound
     */
    function _setApprovalForAll(address, address, bool) internal pure override {
        revert("BookToken: soulbound");
    }

    function bookFactory()
        external
        view
        override
        returns (IBookFactory)
    {
        return factory;
    }
}
