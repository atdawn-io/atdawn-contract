// SPDX-License-Identifier: MIT
// https://atdawn.io/
pragma solidity ^0.8.26;

interface IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external ;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}