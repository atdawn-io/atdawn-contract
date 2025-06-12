// SPDX-License-Identifier: MIT
// https://atdawn.io
// AtDawnMarket
pragma solidity ^0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC1155} from "../interface/IERC1155.sol";
import {IERC20} from "../interface/IERC20.sol";
import {IData} from "../interface/IData.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract AtDawnMarket is OwnableUpgradeable,ERC1155Holder{

    struct Total{
        uint256 token;
        uint256 eth;
    }

    struct Order {
        uint256 id;
        bool isForSale;
        address nftAddress;
        uint256 tokenID;
        uint number;
        address seller;
        bool isToken;
        uint256 minPrice;
        address onlySellTo;
    }

    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant DEV_FUND_PERCENT = 20;
    uint256 public constant POOL_FUND_PERCENT = 20;

    address private paymentToken;
    address private devFundAddress;

    mapping(address => bool) private nftContractList;
    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => Total) salesAmountList;
    mapping(address => uint256[]) accountSalesList;
    mapping(address => uint256[]) accountSoldsList;
    mapping (uint256 => Order) private NFTSalesOrder;

    uint256[] private salesList;
    uint256[] private soldsList;

    uint256 private _indexToAssign = 0;

    uint256[50] private __gap;

    event SellNFT(uint256 _id,address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo,uint256 time);
    event CancelSalesOrder(uint256 _index,address seller,uint256 time);
    event BuyNFT(uint256 _index,address account,uint256 time);
    event Withdraw(address account,uint256 ethValue,uint256 tokenValue,uint256 time);

    function initialize(address initialOwner,address _token,address _devFundAddress) public initializer {
        paymentToken = _token;
        devFundAddress = _devFundAddress;
        __Ownable_init(initialOwner);
    }

    function getNextIndexToAssign() public view returns (uint256) {
        return _getNextIndexToAssign();
    }

    function _getNextIndexToAssign() private view returns (uint256) {
        return _indexToAssign + 1;
    }

    function _incrementIndexToAssign() internal {
        _indexToAssign ++;
    }

    function getPaymentToken() public view returns(address){
        return paymentToken;
    }

    function setPaymentToken(address _address) public onlyOwner{
        paymentToken = _address;
    }

    function addNFTContract(address _nftAddress) public onlyOwner {
        nftContractList[_nftAddress] = true;
    }

    function removeNFTContract(address _nftAddress) public onlyOwner{
        nftContractList[_nftAddress] = false;
    }

    function setDevFundAddress(address _address) public onlyOwner{
        devFundAddress = _address;
    }

    function getDevFundAddress() public view returns(address){
        return devFundAddress;
    }

    
    function sellNFT(address _nftAddress,uint256 _tokenid,uint _number, uint256 _minSalePriceInWei,bool _isToken,address _onlySellTo) public {

        IERC1155 nft = IERC1155(_nftAddress);
        require(nftContractList[_nftAddress] == true,"error: Unsupported nft addresses");
        require(nft.balanceOf(_msgSender(),_tokenid) >= _number,"error: Wallet nft low balance");
        require(nft.isApprovedForAll(_msgSender(),address(this)),"error: nft not approved");

        uint256 _index = _getNextIndexToAssign();
        NFTSalesOrder[_index] = Order(_index,true,_nftAddress,_tokenid,_number,_msgSender(),_isToken,_minSalePriceInWei,_onlySellTo);

        emit SellNFT(_index,_nftAddress,_tokenid,_number,_minSalePriceInWei,_isToken,_onlySellTo,block.timestamp);

        _incrementIndexToAssign();
        nft.safeTransferFrom(_msgSender(), address(this), _tokenid, _number, "0x0");
        balances[_nftAddress][_tokenid] += _number;
        accountSalesList[_msgSender()].push(_index);
        salesList.push(_index);

    }
   
    function cancelSalesOrder(uint256 _index) public {
        require(NFTSalesOrder[_index].isForSale == true,"error: The state of nft is false");
        require(NFTSalesOrder[_index].seller == _msgSender(),"error: nft does not belong to the requester");

        Order storage _offer = NFTSalesOrder[_index];
        IERC1155(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, _offer.number, "0x0");
        _offer.isForSale = false;

        emit CancelSalesOrder(_index,_msgSender(),block.timestamp);

        balances[_offer.nftAddress][_offer.tokenID] -= _offer.number;
        uint256[] storage saless = accountSalesList[_msgSender()];
        for (uint256 i = 0; i < saless.length; i++) {
            if (saless[i] == _index) {
                deleteElement(saless,i); 
                break;
            }
        }
        for (uint256 i = 0; i < salesList.length; i++) {
            if (salesList[i] == _index) {
                deleteElement(salesList,i); 
                break;
            }
        }
    }

    function deleteElement(uint256[] storage dataArray,uint256 index) internal {
        require(index < dataArray.length, "Invalid index");
        dataArray[index] = dataArray[dataArray.length - 1];
        dataArray.pop();
    }

    function buyNFT(uint256 _index) public payable {

        Order storage _offer = NFTSalesOrder[_index];
        require(NFTSalesOrder[_index].isForSale == true,"error: The state of nft is false");
        require(_offer.onlySellTo == address(0x0) || (_offer.onlySellTo != address(0x0) && _offer.onlySellTo == _msgSender()),"error: No order purchase privileges");

        uint256 operatingAmount = _offer.minPrice * DEV_FUND_PERCENT / PERCENTS_DIVIDER;
        uint256 sellerAmount = _offer.minPrice - operatingAmount;
        Total storage sellerTotal = salesAmountList[_offer.seller];
        
        if(_offer.isToken){
            
            require(IERC20(paymentToken).allowance(_msgSender(),address(this)) >= _offer.minPrice && IERC20(paymentToken).balanceOf(_msgSender()) >= _offer.minPrice,"error: Unapproved token or insufficient quota");
            IERC20(paymentToken).transferFrom(_msgSender(), address(this), _offer.minPrice);
            IERC20(paymentToken).transfer(devFundAddress, operatingAmount);
            sellerTotal.token += sellerAmount;

        }else{
            require(msg.value >= _offer.minPrice,"error: Insufficient payment eth");
            
            (bool s, ) = devFundAddress.call{value: operatingAmount}("");require(s);
            
            sellerTotal.eth += sellerAmount;
        }

        balances[_offer.nftAddress][_offer.tokenID] -= _offer.number;
        IERC1155(_offer.nftAddress).safeTransferFrom(address(this), _msgSender(), _offer.tokenID, _offer.number, "0x0");
        _offer.isForSale = false;
        uint256[] storage saless = accountSalesList[_offer.seller];

        for (uint256 i = 0; i < saless.length; i++) {
            if (saless[i] == _index) {
                deleteElement(saless,i);
                break;
            }
        }
        for (uint256 i = 0; i < salesList.length; i++) {
            if (salesList[i] == _index) {
                deleteElement(salesList,i);
                break;
            }
        }

        uint256[] storage solds = accountSoldsList[_offer.seller];
        solds.push(_index);
        soldsList.push(_index);

        emit BuyNFT(_index,_msgSender(),block.timestamp);

    }

    function withdraw() public{
        Total storage _total = salesAmountList[_msgSender()];

        if(_total.eth > 0){
            require(address(this).balance >= _total.eth ,"error: eth Insufficient balance");
            (bool s, ) = _msgSender().call{value: _total.eth}("");require(s);
            _total.eth = 0;
        }
        if(_total.token > 0){
            require(IERC20(paymentToken).balanceOf(address(this)) >= _total.token,"error: token Insufficient balance");
            IERC20(paymentToken).transfer(_msgSender(), _total.token);
            _total.token = 0;
        }

        emit Withdraw(_msgSender(),_total.eth,_total.token,block.timestamp);
    }

    function getUserSalesAmount(address _account) public view returns(Total memory){
        return salesAmountList[_account];
    }

    function getAccountSalesIndex(address _account) public view returns(uint256[] memory){
        return accountSalesList[_account];
    }

    function getAccountSales(address _account) public view returns(Order[] memory orders){
        orders = new Order[](accountSalesList[_account].length);
        for(uint i = 0; i< accountSalesList[_account].length ; i++){
            orders[i] = _queryOrder(accountSalesList[_account][i]);
        }
    }

    function getAccountSoldsIndex(address _account) public view returns(uint256[] memory){
        return accountSoldsList[_account];
    }

    function getAccountSolds(address _account) public view returns(Order[] memory orders){
        orders = new Order[](accountSoldsList[_account].length);
        for(uint i = 0; i< accountSoldsList[_account].length ; i++){
            orders[i] = _queryOrder(accountSoldsList[_account][i]);
        }
    }
    
    function balanceOf(address _nft,uint256 _tokenid) public view returns(uint256){
        return balances[_nft][_tokenid];
    }

    function _queryOrder(uint256 _orderId) internal view returns(Order memory){
        return NFTSalesOrder[_orderId];
    }

    function queryOrder(uint256 _orderId) public view returns(Order memory){
        return _queryOrder(_orderId);
    }

    function getSalesListCount() public view returns(uint256){
        return salesList.length;
    }

    function getSoldsListCount() public view returns(uint256){
        return soldsList.length;
    }

    function getSalesListIndexOrder(uint256 _index) public view returns(Order memory){
        return _queryOrder(salesList[_index]);
    }

    function getSoldsListIndexOrder(uint256 _index) public view returns(Order memory){
        return _queryOrder(soldsList[_index]);
    }

    function getPageSalesOrderAsc(uint256 _size,uint256 _index) public view returns(Order[] memory orders){
        uint256 _length = _index + _size <= getSalesListCount() ? _size : getSalesListCount() - _index + 1;
        orders = new Order[](_length);
        for(uint256 i = 0; i < _length; i++){
            orders[i] = NFTSalesOrder[salesList[i + (_index -1)]];
        }
    }

    function getPageSoldsOrderAsc(uint256 _size,uint256 _index) public view returns(Order[] memory orders){
        uint256 _length = _index + _size <= getSoldsListCount() ? _size : getSoldsListCount()- _index + 1;
        orders = new Order[](_length);
        for(uint256 i = 0; i < _length; i++){
            orders[i] = NFTSalesOrder[soldsList[i + (_index - 1)]];
        }
    }
    
    function getPageSalesOrderDesc(uint256 _size,uint256 _index) public view returns(Order[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new Order[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i + 1] = NFTSalesOrder[salesList[_index - i]];
        }
    }

    function getPageSoldsOrderDesc(uint256 _size,uint256 _index) public view returns(Order[] memory indexArray){
        uint256 _length = _index > _size ? _size : _index;
        indexArray = new Order[](_length);
        for(uint256 i = 1; i <= _length; i++){
            indexArray[i - 1] = NFTSalesOrder[soldsList[_index - i]];
        }
    }

}
