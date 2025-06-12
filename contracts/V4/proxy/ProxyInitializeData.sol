// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract ProxyInitializeData{

    function AvatarAdminInitializeData(address initialOwner,address _avatarNFT,address _devFund,address _data,address _signer) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,address,address)", initialOwner,_avatarNFT,_devFund,_data,_signer);
    }
    
    function BoxInitializeData(address initialOwner,address _weaponNft,address _propNft,address _data) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,address)", initialOwner,_weaponNft,_propNft,_data);
    }

    function DataInitializeData(address initialOwner,address _devFundAddress) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address)", initialOwner,_devFundAddress);
    }

    function MarketInitializeData(address initialOwner,address _token,address _devFundAddress) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address)", initialOwner,_token,_devFundAddress);
    }

    function SettlementInitializeData(address initialOwner,address _signer,address _propsNft,address _avatarNft,address _data) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,address,address)", initialOwner,_signer,_propsNft,_avatarNft,_data);
    }

    function ShopInitializeData(address initialOwner,address _paymentToken,address _data,address _devFundAddress) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,address)", initialOwner,_paymentToken,_data,_devFundAddress);
    }

}