// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnBox

pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC1155} from "../interface/IERC1155.sol";
import {IData} from "../interface/IData.sol";

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract AtDawnBox is OwnableUpgradeable{

    using Address for address;

    struct configure {
        uint256[] weaponIds;
        uint256 keyId; 
        uint256 keyNumber;
        bool state;
    }

    address public weaponNft;
    address public propNft;
    address public data;

    uint256 public totalBoxOpened =0;
    uint256 public OPENBOX_CREDIT = 1000;
    uint256[] public INVITA_CREDIT = [100, 40];

    bool public OpenBoxEnabled = false;

    mapping (uint256 => configure) private boxConfigureList;

    uint256[50] private __gap;

    event SetInvitaCredit(uint256[] _value);
    event SetOpenBoxCredit(uint256 _value);
    event OpenBoxEvent(address account,uint256 tokenid,uint256 boxID,uint256 time);

    function initialize(address initialOwner,address _weaponNft,address _propNft,address _data) public initializer {
        weaponNft = _weaponNft;
        propNft = _propNft;
        data = _data;
        __Ownable_init(initialOwner);
        INVITA_CREDIT = [100, 40];
        OPENBOX_CREDIT = 1000;
        totalBoxOpened =0;
    }

    modifier enableOpenBox() {
        require(OpenBoxEnabled, "error: openbox is not enabled.");
        _;
    }

    function setOpenBoxEnable(bool _state) public onlyOwner{
        OpenBoxEnabled = _state;
    }

    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
        emit SetInvitaCredit(_value);
    }

    function setOpenBoxCredit(uint256 _value) public onlyOwner{
        OPENBOX_CREDIT = _value;
        emit SetOpenBoxCredit(_value);
    }
    

    function setBoxConfigureInfo(uint256 _boxID,uint256[] memory _tokenids,uint256 _keyId,uint256 _number) public onlyOwner{
        boxConfigureList[_boxID].weaponIds = _tokenids;
        boxConfigureList[_boxID].keyId = _keyId;
        boxConfigureList[_boxID].keyNumber = _number;
        boxConfigureList[_boxID].state = true;
    }

    function getBoxConfigureInfo(uint256 _boxID) public view returns(configure memory){
        return boxConfigureList[_boxID];
    }

    function OpenBox(uint256 _boxId) public enableOpenBox {
        require(!_msgSender().isContract(),'error: Requestor is the contractual address');
        require(IERC1155(propNft).balanceOf(_msgSender(), _boxId) > 0 ,'error: Box balance is low');
        require(boxConfigureList[_boxId].state,'error: Configuration for Box does not exist');
        require(IERC1155(propNft).balanceOf(_msgSender(), boxConfigureList[_boxId].keyId) >= boxConfigureList[_boxId].keyNumber ,'error: Key balance is low');

        IERC1155(propNft).burn(_msgSender(),_boxId,1);
        IERC1155(propNft).burn(_msgSender(),boxConfigureList[_boxId].keyId,boxConfigureList[_boxId].keyNumber);

        totalBoxOpened ++;

        uint256[] memory tokenids = boxConfigureList[_boxId].weaponIds;
        uint256 tokenidIndex = random(tokenids.length);
        uint256 tokenid = tokenids[tokenidIndex];
        IERC1155(weaponNft).mint(_msgSender(), tokenid, 1, '0x0');

        emit OpenBoxEvent(_msgSender(),tokenid,_boxId,block.timestamp);

        IData(data).addCredit(_msgSender(), OPENBOX_CREDIT);

        address _referrer = IData(data).referrer(_msgSender());
        
        for(uint256 index = 0 ; index < INVITA_CREDIT.length ; index ++){
            if(_referrer == address(0)) break;
            IData(data).addCredit(_referrer,INVITA_CREDIT[index]);
            _referrer = IData(data).referrer(_referrer);
        }
    }

    function random(uint number) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,
        block.number,
        block.gaslimit,
        totalBoxOpened,
        _msgSender()))) % number;
    }

}


