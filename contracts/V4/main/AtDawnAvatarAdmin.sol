// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnAvatarAdmin

pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAvatarNFT} from "../interface/IAvatarNFT.sol";
import {IData} from "../interface/IData.sol";

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

contract AtDawnAvatarAdmin is OwnableUpgradeable{

    using ECDSA for *;

    address public devFundAddress;
    address public avatarNft;
    address public data;

    address private signerAddress;

    uint256[] public INVITA_CREDIT = [200, 40];
    
    uint256 public MINT_CREDIT = 2000;
    uint256 public MINT_FEES = 0.0008 ether;

    bool public MintEnabled = false;
    mapping(bytes32 => bool) private signerBytesMap;

    uint256[50] private __gap;

    event SetMintEnabled(bool state);
    event SetSignerAddress(address newAddress);
    event SetDevFundAddress(address newAddress);
    event SetAvatarNftAddress(address newAddress);
    event SetDataAddress(address newAddress);
    event SetMintFee(uint256 _fee);
    event SetMintCredit(uint256 _value);
    event SetInvitaCredit(uint256[] _value);
    event MintBasic(string uri);

    
    function initialize(address initialOwner,address _avatarNFT,address _devFund,address _data,address _signer) public initializer {
        avatarNft = _avatarNFT;
        devFundAddress = _devFund;
        data = _data;
        signerAddress = _signer;
        __Ownable_init(initialOwner);
        MINT_CREDIT = 2000;
        MINT_FEES = 0.0008 ether;
        INVITA_CREDIT = [200, 40];
    }

    modifier enableMint() {
        require(MintEnabled, "error: mint nft is not enabled.");
        _;
    }

    function setMintEnabled(bool _state) public onlyOwner{
        MintEnabled = _state;
        emit SetMintEnabled(_state);
    }

    function setSignerAddress(address newAddress) public onlyOwner {
        signerAddress = newAddress;
        emit SetSignerAddress(newAddress);
    }

    function setDevFundAddress(address newAddress) public onlyOwner {
        devFundAddress = newAddress;
        emit SetDevFundAddress(newAddress);
    }

    function setAvatarNftAddress(address newAddress) public onlyOwner {
        avatarNft = newAddress;
        emit SetAvatarNftAddress(newAddress);
    }

    function setDataAddress(address newAddress) public onlyOwner {
        data = newAddress;
        emit SetDataAddress(newAddress);
    }

    function setMintFee(uint256 _fee) public onlyOwner {
        MINT_FEES = _fee;
        emit SetMintFee(_fee);
    }

    function setMintCredit(uint256 _value) public onlyOwner {
        MINT_CREDIT = _value;
        emit SetMintCredit(_value);
    }

    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
        emit SetInvitaCredit(_value);
    }

    function _mintBasic(string memory uri) internal {
        IAvatarNFT(avatarNft).safeMint(_msgSender(),uri);
        emit MintBasic(uri);
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