// SPDX-License-Identifier: MIT
// https://atdawn.io
// AtDawnShop
pragma solidity 0.8.26;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "../interface/IERC20.sol";
import {IData} from "../interface/IData.sol";
import {IERC1155} from "../interface/IERC1155.sol";

contract AtDawnShop is OwnableUpgradeable{

    struct product{
        uint256 tokenId;
        address nftAddress;
        uint256 total;
        uint256 sold;
        uint256 price;
        bool isToken;
        bool state;
    }

    address public devFundAddress;
    address public paymentToken;
    address public data;

    uint256 public BUY_CREDIT = 1000;
    uint256[] public INVITA_CREDIT = [100, 20];
    bool public enableCredit = false;
    uint256 private _nextProductId = 0;

    mapping (uint256 => product) private productList;

    uint256[50] private __gap;

    event SetInvitaCredit(uint256[] _value);
    event SetDevFundAddress(address newAddress);
    event SetBuyCredit(uint256 _value);
    event AddProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken);
    event UpdateProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken);
    event SetPaymentTokenAddress(address _address);
    event Buy(address _account,address _nft,uint256 _tokenID,uint256 _productId);
    event SetProductState(uint256 _id,bool _state);
    event SetEnableCredit(bool _state);


    function initialize(address initialOwner,address _paymentToken,address _data,address _devFundAddress) public initializer {
        paymentToken = _paymentToken;
        data = _data;
        devFundAddress = _devFundAddress;
        __Ownable_init(initialOwner);
        INVITA_CREDIT = [100, 20];
        BUY_CREDIT = 1000;
    }

    function getNextProductId() public view returns (uint256) {
        return _getNextProductId();
    }

    function _getNextProductId() private view returns (uint256) {
        return _nextProductId + 1;
    }

    function _incrementProductId() internal {
        _nextProductId ++;
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
        emit SetDevFundAddress(_address);
    }

    function setTokenAddress(address _address) public onlyOwner{
        paymentToken = _address;
        emit SetPaymentTokenAddress(_address);
    }

    function setEnableCredit(bool _state) public onlyOwner{
        enableCredit = _state;

        emit SetEnableCredit(_state);
    }
    function setBuyCredit(uint256 _value) public onlyOwner{
        BUY_CREDIT = _value;
        emit SetBuyCredit(_value);
    }
    function setInvitaCredit(uint256[] memory _value) public onlyOwner {
        INVITA_CREDIT = _value;
        emit SetInvitaCredit(_value);
    }

    function setProductState(uint256 _id,bool _state) public onlyOwner{
        productList[_id].state = _state;
        emit SetProductState(_id,_state);
    }

    function _addProduct(uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) internal {

        uint256 _id = _getNextProductId();
        productList[_id] = product(_tokenId,_nftAddress,_total,0,_price,_isToken,true);

        _incrementProductId();
        emit AddProduct(_id,_tokenId,_nftAddress,_total,_price,_isToken);
    }

    function addProduct(uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) public onlyOwner{

        _addProduct( _tokenId, _nftAddress, _total, _price, _isToken);

    }

    function ButchAddProduct(uint256[] memory _tokenIds,address[] memory _nftAddresss,uint256[] memory _totals,uint256[] memory _prices,bool[] memory _isTokens) public onlyOwner{
        require(_tokenIds.length == _nftAddresss.length && _tokenIds.length == _totals.length && _tokenIds.length == _prices.length && _tokenIds.length == _isTokens.length, "ERC1155: ids and amounts length mismatch");
        for(uint256 index = 0 ; index < _tokenIds.length ; index++){
            _addProduct( _tokenIds[index], _nftAddresss[index], _totals[index], _prices[index], _isTokens[index]);
        }
    }

    function updateProduct(uint256 _id,uint256 _tokenId,address _nftAddress,uint256 _total,uint256 _price,bool _isToken) public onlyOwner{

        productList[_id].tokenId = _tokenId;
        productList[_id].nftAddress = _nftAddress;
        productList[_id].total = _total;
        productList[_id].price = _price;
        productList[_id].isToken = _isToken;

        emit UpdateProduct( _id, _tokenId, _nftAddress, _total, _price,_isToken);

    }

    function query(uint256 _id) public view returns(product memory){
        return productList[_id];
    }

    function queryList(uint256[] memory _ids) public view returns(product[] memory tmpProductList){
        tmpProductList = new product[](_ids.length);
        for(uint index = 0 ; index < _ids.length ; index++){
            tmpProductList[index] = productList[_ids[index]];
        }
        return tmpProductList;
    }

    function buy(uint256 _id) public payable{

        require(productList[_id].state,"error: Product unavailable.");

        require(productList[_id].sold < productList[_id].total , "error: Insufficient quantities available for sale.");

        if(productList[_id].isToken){

            require(IERC20(paymentToken).balanceOf(_msgSender()) >= productList[_id].price,"error: Insufficient token balance");

            IERC20(paymentToken).transferFrom(_msgSender(), devFundAddress, productList[_id].price);
            
        }else{
            require(msg.value >= productList[_id].price,"error: Insufficient payment eth");
            
            (bool s, ) = devFundAddress.call{value: msg.value}("");require(s);
        }
        productList[_id].sold += 1;

        IERC1155(productList[_id].nftAddress).mint(_msgSender(),productList[_id].tokenId,1,'0x0');

        emit Buy(_msgSender(),productList[_id].nftAddress,productList[_id].tokenId,_id);

        if(enableCredit){
            address referrerAddress = IData(data).referrer(_msgSender());

            for(uint256 index = 0 ; index < INVITA_CREDIT.length ; index ++){
                if(referrerAddress == address(0)) break;
                IData(data).addCredit(referrerAddress,INVITA_CREDIT[index]);
                referrerAddress = IData(data).referrer(referrerAddress);
            }

            IData(data).addCredit(_msgSender(),BUY_CREDIT);
        }
    }

}