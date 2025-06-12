// SPDX-License-Identifier: MIT
// https://atdawn.io/
pragma solidity ^0.8.26;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}