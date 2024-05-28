// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnBox

pragma solidity ^0.8.8;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address account, uint256 id, uint256 value) external ;
}

interface IData{
    function referrer(address _user) external view returns(address);
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

contract AtDawnBox is Ownable{

    using SafeMath for uint256;
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

    event OpenBoxEvent(address account,uint256 tokenid,uint256 boxID,uint256 time);

    constructor (address _weaponNft,address _propNft,address _data) {
        weaponNft = _weaponNft;
        propNft = _propNft;
        data = _data;
    }

    modifier enableOpenBox() {
        require(OpenBoxEnabled, "error: openbox is not enabled.");
        _;
    }

    function setOpenBoxEnable(bool _state) public onlyOwner{
        OpenBoxEnabled = _state;
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


