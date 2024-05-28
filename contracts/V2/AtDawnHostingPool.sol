// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnHostingPool
pragma solidity ^0.8.8;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface INFT {
    function setApprovalForAll(address operator, bool approved) external;
}

abstract contract Ownable {
    address private _owner;
 
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner,"Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            _owner = newOwner;
        }
    }
}

contract AtDawnHostingPool is Ownable{

    mapping (address => bool) private sendUser;

    modifier onlySend() {
        require(isSend(msg.sender) || owner() == msg.sender, "Role: caller does not have the distribute role or above");
        _;
    }

    function isSend(address account) public view returns (bool) {
        return sendUser[account];
    }

    function addSend(address account) public onlyOwner{
        sendUser[account] = true;
    }

    function removeSend(address account) public onlyOwner{
        sendUser[account] = false;
    }
    
    function approveTokenPool(address token, address operator, uint256 amount) public onlyOwner {
        IERC20(token).approve(operator, amount);
    }

    function approveNFTPool(address nft, address operator, bool approved) public onlyOwner {
        INFT(nft).setApprovalForAll(operator, approved);
    }

    function sendGas(address to, uint256 amount) public onlySend {
        (bool s, ) = to.call{value: amount}("");require(s);
    }

    receive() external payable {}
    
}
