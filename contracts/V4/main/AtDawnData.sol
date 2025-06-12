// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnData
pragma solidity ^0.8.26;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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

contract AtDawnData is OwnableUpgradeable{

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

    uint256 public FEES = 0.0015 ether;
    uint256 public REGISTER_CREDIT = 5000;

    address public devFundAddress;

    mapping (address => bool) private systemUser;
    mapping (address => userInfo) private userInfoMap;
    mapping(string => address) private codes;

    uint256 private _currentReferrerNum = 0;

    uint256[50] private __gap;

    event Register(address referrer,string code,uint256 time);
    event AddExp(address _user,uint256 _value,uint256 time);
    event SubExp(address _user,uint256 _value,uint256 time);
    event AddInvitaNum(address _user,uint256 _value,uint256 time);
    event SubInvitaNum(address _user,uint256 _value,uint256 time);
    event AddCredit(address _user,uint256 _value,uint256 time);
    event SubCredit(address _user,uint256 _value,uint256 time);
    event AddBonus(address _user,uint256 _value,uint256 time);
    event SubBonus(address _user,uint256 _value,uint256 time);
    event SetReferrer(address _user,address _referrer,uint256 time);
    event System(address account,bool value);
    event SetDevFundAddress(address account);
    event SetRegditCredit(uint256 _value);
    event SetFee(uint256 _fee);

    modifier onlySystem() {
        require(isSystem(_msgSender()) || owner() == _msgSender(), "Role: caller does not have the System role or above");
        _;
    }
    function initialize(address initialOwner,address _devFundAddress) public initializer {
        devFundAddress = _devFundAddress;
        REGISTER_CREDIT = 5000;
        FEES = 0.0015 ether;
        __Ownable_init(initialOwner);
    }

    function isSystem(address account) public view returns (bool) {
        return systemUser[account];
    }

    function addSystem(address account) public onlyOwner{
        systemUser[account] = true;
        emit System(account,true);
    }

    function removeSystem(address account) public onlyOwner{
        systemUser[account] = false;
        emit System(account,false);
    }

    function setDevFundAddress(address account) public onlyOwner{
        devFundAddress = account;
        emit SetDevFundAddress(account);
    }

    function getNextNumber() public view returns (uint256) {
        return _getNextNumber();
    }

    function _getNextNumber() internal view returns (uint256) {
        return _currentReferrerNum + 1;
    }

    function _incrementReferrerCode() internal  {
        _currentReferrerNum ++;
    }

    function exp(address _user) public view returns(uint256){
        return userInfoMap[_user].exp;
    }
    
    function addExp(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].exp += _value;
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
        emit AddExp(_user,_value,block.timestamp);
    }

    function subExp(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].exp -= _value;
        emit SubExp(_user,_value,block.timestamp);
    }

    function invitaNum(address _user) public view returns(uint256){
        return userInfoMap[_user].invitaNum;
    }

    function addInvitaNum(address _user,uint256 _value) public onlySystem{
         if(userInfoMap[_user].state){
            userInfoMap[_user].invitaNum += _value;
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
        emit AddInvitaNum(_user,_value,block.timestamp);
    }

    function subInvitaNum(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].invitaNum -= _value;
        emit SubInvitaNum(_user,_value,block.timestamp);
    }

    function credit(address _user) public view returns(uint256){
        return userInfoMap[_user].credit;
    }

    function addCredit(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].credit += _value;
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
        emit AddCredit(_user,_value,block.timestamp);
    }

    function subCredit(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].credit -= _value;
        emit SubCredit(_user,_value,block.timestamp);
    }

    function bonus(address _user) public view returns(uint256){
        return userInfoMap[_user].bonus;
    }

    function addBonus(address _user,uint256 _value) public onlySystem{
        if(userInfoMap[_user].state){
            userInfoMap[_user].bonus += _value;
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
        emit AddBonus(_user,_value,block.timestamp);
    }

    function subBonus(address _user,uint256 _value) public onlySystem{
        userInfoMap[_user].bonus -= _value;
        emit SubBonus(_user,_value,block.timestamp);
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
        emit SetReferrer(_user,_referrer,block.timestamp);
    }

    function setFee(uint256 _fee) public onlyOwner {
        FEES = _fee;
        emit SetFee(_fee);
    }

    function setRegditCredit(uint256 _value) public onlyOwner{
        REGISTER_CREDIT = _value;
        emit SetRegditCredit(_value);
    }

    function register() public payable{

        require(bytes(userInfoMap[_msgSender()].code).length == 0,"error: Address is registered");

        require(msg.value >= FEES , 'error: Insufficient registration fees');

        string memory _code = generateCode(_getNextNumber());

        codes[_code] = _msgSender();

        if(userInfoMap[_msgSender()].state){

            userInfoMap[_msgSender()].code = _code;
            userInfoMap[_msgSender()].credit += REGISTER_CREDIT;

        }else{
            userInfoMap[_msgSender()] = userInfo({
            code : _code,
            referrer : address(0),
            exp : 0,
            credit : REGISTER_CREDIT,
            invitaNum : 0,
            bonus : 0,
            state : true
            });
        }

        _incrementReferrerCode();

        emit Register( _msgSender(),_code,block.timestamp);
        emit AddCredit( _msgSender(),REGISTER_CREDIT,block.timestamp);

        (bool s, ) = devFundAddress.call{value: msg.value}("");require(s);
        
    }

    function generateCode(uint256 number) internal view returns(string memory){
        string[62] memory seeds = ['0','1','2','3','4','5','6','7','8','9','q','w','e','r','t','y','u','i','o','p','a','s','d','f','g','h','j','k','l','z','x','c','v','b','n','m','Q','W','E','R','T','Y','U','I','O','P','A','S','D','F','G','H','J','K','L','Z','X','C','V','B','N','M'];
        string memory _code;
        for(uint index= 1;index <= 8 ; index++){
            uint seedsIndex = random(number,index,seeds.length);
            _code = _code.strConcat(seeds[seedsIndex]);
        }
        return _code;
    }

    function random(uint number,uint _no,uint size) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        number,
        _msgSender(),
        _no))) % size;
    }
    
}

