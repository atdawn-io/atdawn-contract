// SPDX-License-Identifier: MIT
// https://atdawn.io
// AtDawnSettlement

pragma solidity 0.8.26;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IData} from "../interface/IData.sol";
import {IERC1155} from "../interface/IERC1155.sol";
import {IERC721} from "../interface/IERC721.sol";

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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract AtDawnSettlement is OwnableUpgradeable{

    using Address for address;
    using ECDSA for *;

    struct userInfo {
        uint256 count; 
        uint256 lasttime;
        uint256 lasttokenid;
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
    address public avatarNft;
    bool public SubmitEnabled = false;

    uint256[50] private __gap;

    event SetSubmitEnabled(bool state);
    event SetDataAddress(address _data);
    event SetAvatarAddress(address _avatar);
    event SetPropNftAddress(address _prop);
    event SetIntervalTime(uint256 _time);
    event SetPropTokenID(uint256[] _tokenids);
    event SetSignerAddress(address _signer);
    event SetScoreThreshold(uint256 _num);
    event SetSettlementCredit(uint256 _value);
    event SetInvitaCredit(uint256[] _value);
    event Submit(address user,uint256 score,uint256 time);
    event AwardNFT(address user,address nftAddress,uint256 tokenid,uint256 number,uint256 time);

    function initialize(address initialOwner,address _signer,address _propsNft,address _avatarNft,address _data) public initializer {
        signerAddress = _signer;
        propsNft = _propsNft;
        avatarNft = _avatarNft;
        data = _data;
        __Ownable_init(initialOwner);
        INTERVAL_TIME = 4 minutes;
        SCORE_THRESHOLD = 500;
        BoxIDs = [1,2,3,4,5,6,7];
        SETTLEMENT_CREDIT = 100;
        INVITA_CREDIT = [5, 1];
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
        emit SetDataAddress(_data);
    }

    function setAvatarAddress(address _avatar) public onlyOwner{
        avatarNft = _avatar;
        emit SetAvatarAddress(_avatar);
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

    function getUserLastTokenId(address _account) public view returns (uint256){
        return userInfoMap[_account].lasttokenid;
    }

    function setPropNftAddress(address _newNFTAddress) public onlyOwner{
        propsNft = _newNFTAddress;
        emit SetPropNftAddress(_newNFTAddress);
    }

    function setIntervalTime(uint256 _newTime) public onlyOwner{
        INTERVAL_TIME = _newTime;
        emit SetIntervalTime(_newTime);
    }

    function setPropTokenID(uint256[] memory _newTokenId) public onlyOwner{
        BoxIDs = _newTokenId;
        emit SetPropTokenID(_newTokenId);
    }

    function setSignerAddress(address _newAddress) public onlyOwner {
        signerAddress = _newAddress;
        emit SetSignerAddress(_newAddress);
    }

    function setScoreThreshold(uint256 _newNum) public onlyOwner{
        SCORE_THRESHOLD = _newNum;
        emit SetScoreThreshold(_newNum);
    }

    function setSettlementCredit(uint256 _value) public onlyOwner {
        SETTLEMENT_CREDIT = _value;
        emit SetSettlementCredit(_value);
    }

    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
        emit SetInvitaCredit(_value);
    }

    function submit(bytes32 _hashedMessage,bytes memory _signature, uint256 _score) public enableSubmit{

        require(!_msgSender().isContract(),'error: Requestor is the contractual address');
        require(IERC721(avatarNft).balanceOf(_msgSender())>0, "error: Wallet without avatar nft");
        require(ECDSA.VerifyMessage(_hashedMessage,_signature,signerAddress), "error: Invalid signature");
        require(signerBytesMap[_hashedMessage] == false ,"error: Signature used");
        require(block.timestamp - userInfoMap[_msgSender()].lasttime >= INTERVAL_TIME,"error: Insufficient interval time");

        if(userInfoMap[_msgSender()].issubmit){
             userInfoMap[_msgSender()].count += 1;
             userInfoMap[_msgSender()].lasttime = block.timestamp;
        }else{
            userInfoMap[_msgSender()] = userInfo({
                count : 1,
                lasttime : block.timestamp,
                lasttokenid : 0,
                issubmit : true
            });
        }

        if(_score >= SCORE_THRESHOLD){

            uint256 tokenID = BoxIDs[random(_score,BoxIDs.length)];
            IERC1155(propsNft).mint(_msgSender(),tokenID,1,'0x0');
            emit AwardNFT(_msgSender(),propsNft,tokenID,1,block.timestamp);
            userInfoMap[_msgSender()].lasttokenid = tokenID;
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
