// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract AtDawnProxy is TransparentUpgradeableProxy {

    constructor(address _logic, address admin_, bytes memory _data) TransparentUpgradeableProxy(_logic, admin_, _data){}

    /**
     * @dev Returns the admin of this proxy.
     */
    function proxyAdmin() public view virtual returns (address) {
        return _proxyAdmin();
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    receive() external payable {}

}