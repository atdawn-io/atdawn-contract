// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract AtDawnProxyAdmin is ProxyAdmin {
    constructor(address admin_) ProxyAdmin(admin_) {}
}