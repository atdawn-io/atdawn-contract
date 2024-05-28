// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnAvatarAdmin

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IAvatarNFT {
    function safeMint(address to, string memory uri) external;
}

interface IData{
    function codeAddress(string memory _code) external view returns(address);
    function setReferrer(address _user,address _referrer) external;
    function addInvitaNum(address _user,uint256 _value) external;
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

contract AtDawnAvatarAdmin is Ownable{

    using SafeMath for uint256;
    using ECDSA for *;

    address public devFundAddress;
    address public avatarNft;
    address public data;

    address private signerAddress;

    uint256[] public INVITA_CREDIT = [200, 40];
    
    uint256 public MINT_CREDIT = 2000;
    uint256 public MINT_FEES = 0.001 ether;

    bool public MintEnabled = false;
    mapping(bytes32 => bool) private signerBytesMap;

    event SetMintEnabled(bool state);

    constructor(address _avatarNFT,address _devFundAddress,address _data,address _signer) {

        avatarNft = _avatarNFT;
        devFundAddress = _devFundAddress;
        data = _data;
        signerAddress = _signer;
    }

    modifier enableMint() {
        require(MintEnabled, "error: mint nft is not enabled.");
        _;
    }

    /**
     * @dev 
     */
    function setMintEnabled(bool _state) public onlyOwner{
        MintEnabled = _state;
        emit SetMintEnabled(_state);
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }

    function setDevFundAddress(address newAddress) public onlyOwner {
        devFundAddress = newAddress;
    }

    function setAvatarNftAddress(address newAddress) public onlyOwner {
        avatarNft = newAddress;
    }

    function setDataAddress(address newAddress) public onlyOwner {
        data = newAddress;
    }

    function setMintFee(uint256 _fee) public onlyOwner {
        MINT_FEES = _fee;
    }

    function setMintCredit(uint256 _value) public onlyOwner {
        MINT_CREDIT = _value;
    }

    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
    }

    function _mintBasic(string memory uri) internal {
        IAvatarNFT(avatarNft).safeMint(_msgSender(),uri);
    }

    /**
     * @dev  mint basic nft 
     */
    function mintBasic(bytes32 _hashedMessage,bytes memory _signature, string memory referrerCode, string memory uri) public payable enableMint{

        require(ECDSA.VerifyMessage(_hashedMessage,_signature,signerAddress), "error: Invalid signature");
        require(!signerBytesMap[_hashedMessage] ,"error: Signature used");
        require(msg.value >= MINT_FEES , 'error: Insufficient Mint fees');

        address referrerAddress = IData(data).referrer(_msgSender());
        if( referrerAddress == address(0)){

            address _referrer = IData(data).codeAddress(referrerCode);

            require(_referrer != _msgSender() && _referrer != address(0), 'error: Invalid referrer code');

            IData(data).setReferrer(_msgSender(),_referrer);

            IData(data).addInvitaNum(_referrer,1);

            referrerAddress = _referrer;
            
        }

        for(uint256 index = 0 ; index < INVITA_CREDIT.length ; index ++){
            if(referrerAddress == address(0)) break;
            IData(data).addCredit(referrerAddress,INVITA_CREDIT[index]);
            referrerAddress = IData(data).referrer(referrerAddress);
        }

        IData(data).addCredit(_msgSender(),MINT_CREDIT);

        _mintBasic(uri);

        signerBytesMap[_hashedMessage] = true;

        (bool s, ) = devFundAddress.call{value: msg.value}("");require(s);
    }


}