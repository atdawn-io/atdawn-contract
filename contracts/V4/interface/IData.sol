// SPDX-License-Identifier: MIT
// https://atdawn.io/
pragma solidity ^0.8.26;

interface IData{
    function codeAddress(string memory _code) external view returns(address);
    function setReferrer(address _user,address _referrer) external;
    function addInvitaNum(address _user,uint256 _value) external;
    function referrer(address _user) external view returns(address);
    function addExp(address _user,uint256 _value) external;
    function exp(address _user) external view returns(uint256);
    function credit(address _user) external view returns(uint256);
    function addCredit(address _user,uint256 _value) external;
}