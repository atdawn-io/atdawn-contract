// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnData
pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

/**
 * @dev String operations.
 */
library Strings {
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++)bret[k++] = _bb[i];
        return string(ret);
    }
}


abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AtDawnData is Ownable{

    using SafeMath for uint256;
    using Strings for string;

    struct userInfo {
        string code;
        address referrer;
        uint256 exp; 
        uint256 credit;
        uint256 invitaNum;
        uint256 bonus;
        bool state;
    }

    uint256 constant public FEES = 10 ether;

    address private devFundAddress;

    mapping (address => bool) private systemUser;
    mapping (address => userInfo) private userInfoMap;
    mapping(string => address) private codes;

    uint256 private _currentReferrerNum = 0;

    event Register(address referrer,string code,uint256 time);

    modifier onlySystem() {
        require(isSystem(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the System role or above");
        _;
    }

    constructor (address _devFundAddress) {
        devFundAddress = _devFundAddress;
    }

    function isSystem(address account) public view returns (bool) {
        return systemUser[account];
    }

    function addSystem(address account) public onlyOwner{
        systemUser[account] = true;
    }

    function removeSystem(address account) public onlyOwner{
        systemUser[account] = false;
    }

    function setDevFundAddress(address account) public onlyOwner{
        devFundAddress = account;
    }

    function getNextNumber() public view returns (uint256) {
        return _currentReferrerNum.add(1);
    }

    function _getNextNumber() internal view returns (uint256) {
        return _currentReferrerNum.add(1);
    }

    function _incrementReferrerCode() internal  {
        _currentReferrerNum ++;
    }

    function exp(address _user) public view returns(uint256){
        return userInfoMap[_user].exp;
    }
    
    function addExp(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].exp = userInfoMap[_user].exp.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : '',
            referrer : address(0),
            exp : _value,
            credit : 0,
            invitaNum : 0,
            bonus : 0,
            state : true
            });
        }
    }

    function subExp(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].exp = userInfoMap[_user].exp.sub(_value);
    }

    function invitaNum(address _user) public view returns(uint256){
        return userInfoMap[_user].invitaNum;
    }

    function addInvitaNum(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].invitaNum = userInfoMap[_user].invitaNum.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : '',
            referrer : address(0),
            exp : 0,
            credit : 0,
            invitaNum : _value,
            bonus : 0,
            state : true
            });
        }
    }

    function subInvitaNum(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].invitaNum = userInfoMap[_user].invitaNum.sub(_value);
    }

    function credit(address _user) public view returns(uint256){
        return userInfoMap[_user].credit;
    }

    function addCredit(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].credit = userInfoMap[_user].credit.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : '',
            referrer : address(0),
            exp : 0,
            credit : _value,
            invitaNum : 0,
            bonus : 0,
            state : true
            });
        }
    }

    function subCredit(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].credit = userInfoMap[_user].credit.sub(_value);
    }

    function bonus(address _user) public view returns(uint256){
        return userInfoMap[_user].bonus;
    }

    function addBonus(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].bonus = userInfoMap[_user].bonus.add(_value);
        }else{
            userInfoMap[_user] = userInfo({
            code : '',
            referrer : address(0),
            exp : 0,
            credit : 0,
            invitaNum : 0,
            bonus : _value,
            state : true
            });
        }
    }

    function subBonus(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].bonus = userInfoMap[_user].bonus.sub(_value);
    }

    function referrer(address _user) public view returns(address){
        return userInfoMap[_user].referrer;
    }

    function codeAddress(string memory _code) public view returns(address){
        return codes[_code];
    }

    function code(address _user) public view returns(string memory){
        return userInfoMap[_user].code;
    }

    function setReferrer(address _user,address _referrer) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].referrer = _referrer;
        }else{
            userInfoMap[_user] = userInfo({
            code : '',
            referrer : _referrer,
            exp : 0,
            credit : 0,
            invitaNum : 0,
            bonus : 0,
            state : true
            });
        }
    }

    function register() public payable{

        require(bytes(userInfoMap[_msgSender()].code).length == 0,"error: Address is registered");

        require(msg.value >= FEES , 'error: Insufficient registration fees');

        string memory _code = generateCode(_getNextNumber());

        codes[_code] = _msgSender();

        if(userInfoMap[_msgSender()].state){

            userInfoMap[_msgSender()].code = _code;

        }else{
            userInfoMap[_msgSender()] = userInfo({
            code : _code,
            referrer : address(0),
            exp : 0,
            credit : 0,
            invitaNum : 0,
            bonus : 0,
            state : true
            });
        }

        _incrementReferrerCode();

        emit Register( _msgSender(),_code,block.timestamp);

        (bool s, ) = devFundAddress.call{value: msg.value}("");require(s);
        
    }

    function generateCode(uint256 number) internal view returns(string memory){
        string[36] memory seeds = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','k','u','v','w','x','y','z'];
        string memory _code;
        for(uint index= 1;index <= 8 ; index++){
            uint seedsIndex = random(number,index,seeds.length);
            _code = _code.strConcat(seeds[seedsIndex]);
        }
        return _code;
    }

    function random(uint number,uint _seend,uint size) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        number,
        _msgSender(),
        _seend,
        msg.sender))) % size;
    }
    
}

