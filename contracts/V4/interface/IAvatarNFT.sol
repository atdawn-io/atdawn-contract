// SPDX-License-Identifier: MIT
// https://atdawn.io/
pragma solidity ^0.8.26;

interface IAvatarNFT {
    function safeMint(address to, string memory uri) external;
}