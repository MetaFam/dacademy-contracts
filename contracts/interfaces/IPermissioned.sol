// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IPermissioned {
  function hasPermission(
    address account
  ) external view returns (bool);

  function hasPermission(
    address account,
    uint256 permission
  ) external view returns (bool);
}