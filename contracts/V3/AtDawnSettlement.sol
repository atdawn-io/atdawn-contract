// SPDX-License-Identifier: MIT
// https://atdawn.io
// AtDawnSettlement

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


library ECDSA {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }
        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function VerifyMessage(bytes32 _hashedMessage, bytes memory _signature , address signerAddress) internal pure returns (bool) {
        address signer = recover(_hashedMessage,_signature);
        if(signer == signerAddress)
            return true;
        else
            return false;
    }

}

interface IERC1155 {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}

interface IData{
    function referrer(address _user) external view returns(address);
    function addExp(address _user,uint256 _value) external;
    function exp(address _user) external view returns(uint256);
    function credit(address _user) external view returns(uint256);
    function addCredit(address _user,uint256 _value) external;
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract AtDawnSettlement is Ownable{

    using SafeMath for uint256;
    using Address for address;
    using ECDSA for *;

    struct userInfo {
        uint256 count; 
        uint256 lasttime;
        bool issubmit;
    }

    mapping(address => userInfo) private userInfoMap;
    mapping(bytes32 => bool) private signerBytesMap;

    address private signerAddress;
    uint256 public INTERVAL_TIME = 4 minutes;
    uint256 public SCORE_THRESHOLD = 500;

    uint256[] public BoxIDs = [1,2,3,4,5,6,7];
    uint256 public SETTLEMENT_CREDIT = 100;
    uint256[] public INVITA_CREDIT = [5, 1];

    address public propsNft;
    address public data;
    bool public SubmitEnabled = false;

    event SetSubmitEnabled(bool state);
    event Submit(address user,uint256 score,uint256 time);
    event AwardNFT(address user,address nftAddress,uint256 tokenid,uint256 number,uint256 time);

    constructor (address _signer,address _propsNft,address _data) {
        signerAddress = _signer;
        propsNft = _propsNft;
        data = _data;
    }

    modifier enableSubmit() {
        require(SubmitEnabled, "error: submit is not enabled.");
        _;
    }

    function setSubmitEnabled(bool _state) public onlyOwner{
        SubmitEnabled = _state;
        emit SetSubmitEnabled(_state);
    }

    function exp(address _user) public view returns(uint256){
        return IData(data).exp(_user);
    }

    function credit(address _user) public view returns(uint256){
        return IData(data).credit(_user);
    }

    function setDataAddress(address _data) public onlyOwner{
        data = _data;
    }

    function getUserisSubmit(address _account) public view returns(bool){
        return userInfoMap[_account].issubmit;
    }

    function getUserSubmitCount(address _account) public view returns(uint256){
        return userInfoMap[_account].count;
    }

    function getUserSubmitLastTime(address _account) public view returns(uint256){
        return userInfoMap[_account].lasttime;
    }

    function setPropNftAddress(address _newNFTAddress) public onlyOwner{
        propsNft = _newNFTAddress;
    }

    function setIntervalTime(uint256 _newTime) public onlyOwner{
        INTERVAL_TIME = _newTime;
    }

    function setPropTokenID(uint256[] memory _newTokenId) public onlyOwner{
        BoxIDs = _newTokenId;
    }

    function setSignerAddress(address _newAddress) public onlyOwner {
        signerAddress = _newAddress;
    }

    function setScoreThreshold(uint256 _newNum) public onlyOwner{
        SCORE_THRESHOLD = _newNum;
    }

    function setSettlementCredit(uint256 _value) public onlyOwner {
        SETTLEMENT_CREDIT = _value;
    }

    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
    }

    function submit(bytes32 _hashedMessage,bytes memory _signature, uint256 _score) public enableSubmit{
        require(!_msgSender().isContract(),'error: Requestor is the contractual address');
        require(ECDSA.VerifyMessage(_hashedMessage,_signature,signerAddress), "error: Invalid signature");
        require(signerBytesMap[_hashedMessage] == false ,"error: Signature used");
        require(block.timestamp.sub(userInfoMap[_msgSender()].lasttime) >= INTERVAL_TIME,"error: Insufficient interval time");

        if(userInfoMap[_msgSender()].issubmit){
             userInfoMap[_msgSender()].count = userInfoMap[_msgSender()].count.add(1);
             userInfoMap[_msgSender()].lasttime = block.timestamp;
        }else{
            userInfoMap[_msgSender()] = userInfo({
                count : 1,
                lasttime : block.timestamp,
                issubmit : true
            });
        }

        if(_score >= SCORE_THRESHOLD){

            uint256 tokenID = BoxIDs[random(_score,BoxIDs.length)];
            IERC1155(propsNft).mint(_msgSender(),tokenID,1,'0x0');
            emit AwardNFT(_msgSender(),propsNft,tokenID,1,block.timestamp);

        }

        emit Submit(_msgSender(),_score,block.timestamp);
        
        IData(data).addExp(_msgSender(), _score);
        IData(data).addCredit(_msgSender(), SETTLEMENT_CREDIT);

        address _referrer = IData(data).referrer(_msgSender());
        
        for(uint256 index = 0 ; index < INVITA_CREDIT.length ; index ++){
            if(_referrer == address(0)) break;
            IData(data).addCredit(_referrer,INVITA_CREDIT[index]);
            _referrer = IData(data).referrer(_referrer);
        }


    }

    function random(uint number,uint size) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        number,
        msg.sender))) % size;
    }

}
