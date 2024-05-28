// SPDX-License-Identifier: MIT
// https://atdawn.io/
// AtDawnBasicFi

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IBasicNFT {
    function tokenLevel(uint256 tokenId) external view returns(uint256);
    function setTokenLevel(uint256 tokenId,uint256 _level) external;
    function safeMint(address to, string memory uri) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IData{
    function codeAddress(string memory _code) external view returns(address);
    function setReferrer(address _user,address _referrer) external;
    function addInvitaNum(address _user,uint256 _value) external;
    function referrer(address _user) external view returns(address);
    function addBonus(address _user,uint256 _value) external;
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

contract AtDawnBasicFi is Ownable{

    using SafeMath for uint256;
    using ECDSA for *;

    address private token;
    address private devFundAddress;
    address private basicNft;
    address private hostingPool;
    address private data;

    uint256 constant private PERCENTS_DIVIDER = 1000;

    uint256[] private REFERRAL_PERCENTS = [50, 10];

    uint256 private DEVFUND_PERCENTS = 50;

    uint256 constant private UPGRADE_BASE = 10 ether;

    uint256 constant public TIME_STEP = 60 days;

    uint256 public totalNFTs;
    uint256 public totalUpgrade;
    address private signerAddress;

    bool public MintEnabled = false;
    bool public UpgradeEnabled = false;

    struct Record {
        uint256 amount;
        uint256 rewards;
        uint256 start;
    }

    struct NFT {
        Record[] records;
        uint256 checkpoint;
        uint256 total;
    }

    mapping (uint256 => NFT) internal nfts;
    mapping(bytes32 => bool) private signerBytesMap;

    event SetMintEnabled(bool state);
    event SetUpgradeEnabled(bool state);
    event Newbie(uint256 tokenId);
    event NewRecord(uint256 tokenId, uint256 amount);
    event RefBonus(address referrer, address referral, uint256 level, uint256 amount);
    event Claim(address account, uint256 tokenId, uint256 amount);

    constructor(address _token, address _basicNFT, address _devFundAddress, address _hostingPool,address _data,address _signer) {
        token = _token;
        basicNft = _basicNFT;
        devFundAddress = _devFundAddress;
        hostingPool = _hostingPool;
        data = _data;
        signerAddress = _signer;
    }

    modifier enableMint() {
        require(MintEnabled, "error: mint nft is not enabled.");
        _;
    }

    modifier enableUpgrade() {
        require(UpgradeEnabled, "error: upgrade nft is not enabled.");
        _;
    }

    modifier nftMine(uint256 tokenId){
        require(IBasicNFT(basicNft).ownerOf(tokenId) == _msgSender() ,'error: Not the nft owner');
        _;
    }

    /**
     * @dev 
     */
    function setUpgradeEnabled(bool _state) public onlyOwner{
        UpgradeEnabled = _state;
        emit SetUpgradeEnabled(_state);
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

    function getSignerAddress() public view returns(address){
        return signerAddress;
    }

    /**
     * @dev  mint basic nft 
     */
    function mintBasic(bytes32 _hashedMessage,bytes memory _signature, string memory referrerCode, string memory uri) public enableMint{

        require(ECDSA.VerifyMessage(_hashedMessage,_signature,signerAddress), "error: Invalid signature");
        require(!signerBytesMap[_hashedMessage] ,"error: Signature used");

        if(IData(data).referrer(_msgSender()) == address(0)){

            address _referrer = IData(data).codeAddress(referrerCode);

            require(_referrer != _msgSender() && _referrer != address(0), 'error: Invalid referrer code');

            IData(data).setReferrer(_msgSender(),_referrer);

            IData(data).addInvitaNum(_referrer,1);
        }
        
        _mintBasic(uri);

        signerBytesMap[_hashedMessage] = true;
    }

    function _mintBasic(string memory uri) internal {
        IBasicNFT(basicNft).safeMint(_msgSender(),uri);
    }

    /**
     * @dev  upgrade basic nft 
     */
    function upgradeBasic(uint256 tokenId) public enableUpgrade nftMine(tokenId){

        uint _Level = IBasicNFT(basicNft).tokenLevel(tokenId);

        uint256 _nextLevelValue = _Level.add(1).mul(UPGRADE_BASE);

        require(IERC20(token).balanceOf(_msgSender()) >= _nextLevelValue, 'error: Insufficient token balance');

        address _referrer = IData(data).referrer(_msgSender());

        for(uint256 index = 0 ; index < REFERRAL_PERCENTS.length ; index ++){

            if(_referrer == address(0)) break;

            uint256 referrerFee = (_Level.add(1).mul(UPGRADE_BASE)).mul(REFERRAL_PERCENTS[index]).div(PERCENTS_DIVIDER);

            IERC20(token).transferFrom(_msgSender(), _referrer, referrerFee);
            
            _nextLevelValue = _nextLevelValue.sub(referrerFee);

            IData(data).addBonus(_referrer,referrerFee);
            
            emit RefBonus(_referrer, _msgSender(), index.add(1), referrerFee);

            _referrer = IData(data).referrer(_referrer);

        }

        IERC20(token).transferFrom(_msgSender(), hostingPool, _nextLevelValue);

        IBasicNFT(basicNft).setTokenLevel(tokenId,_Level.add(1));

        NFT storage nftData = nfts[tokenId];

        if (nftData.records.length == 0) {
            nftData.checkpoint = block.timestamp;
            totalNFTs = totalNFTs.add(1);
            emit Newbie(tokenId);
        }

        nftData.records.push(Record(_Level.add(1).mul(UPGRADE_BASE), 0, block.timestamp));

        totalUpgrade = totalUpgrade.add(_Level.add(1).mul(UPGRADE_BASE));

        emit NewRecord(tokenId, _Level.add(1).mul(UPGRADE_BASE));
    }

    /**
     * @dev  claim nft tokens
     */
    function claim(uint256 tokenId) public nftMine(tokenId){

        NFT storage nftData = nfts[tokenId];

        uint256 totalRewards;
        uint256 rewards;

        for (uint256 i = 0; i < nftData.records.length; i++) {

            if (nftData.records[i].rewards < nftData.records[i].amount.mul(2)) {

                rewards = (nftData.records[i].amount)
                    .mul(block.timestamp.sub(nftData.checkpoint))
                    .div(TIME_STEP);

                if (nftData.records[i].rewards.add(rewards) > nftData.records[i].amount.mul(2)) {
                    rewards = (nftData.records[i].amount.mul(2)).sub(nftData.records[i].rewards);
                }

                nftData.records[i].rewards = nftData.records[i].rewards.add(rewards); 
                totalRewards = totalRewards.add(rewards);
            }

        }

        nftData.checkpoint = block.timestamp;

        nftData.total = nftData.total.add(totalRewards);

        uint256 devFundRewards = totalRewards.mul(DEVFUND_PERCENTS).div(PERCENTS_DIVIDER);

        require(IERC20(token).balanceOf(hostingPool) >= (totalRewards.add(devFundRewards)), 'error: HostingPool balance is insufficient');

        IERC20(token).transferFrom(hostingPool, _msgSender(), totalRewards);

        IERC20(token).transferFrom(hostingPool, devFundAddress, devFundRewards);

        emit Claim(_msgSender(),tokenId, totalRewards);

    }

    /**
     * @dev The token needed for the next level of nft
     */
    function getNextLevelValue(uint256 tokenId) public view returns(uint256){
        return IBasicNFT(basicNft).tokenLevel(tokenId).add(1).mul(UPGRADE_BASE);
    }

    /**
     * @dev nft can currently collect tokens
     */
    function getNftRewards(uint256 tokenId) public view returns (uint256) {

        NFT memory nftData = nfts[tokenId];

        uint256 totalRewards;
        uint256 rewards;

        for (uint256 i = 0; i < nftData.records.length; i++) {

            if (nftData.records[i].rewards < nftData.records[i].amount.mul(2)) {

                rewards = (nftData.records[i].amount)
                    .mul(block.timestamp.sub(nftData.checkpoint))
                    .div(TIME_STEP);

                if (nftData.records[i].rewards.add(rewards) > nftData.records[i].amount.mul(2)) {
                    rewards = (nftData.records[i].amount.mul(2)).sub(nftData.records[i].rewards);
                }

                totalRewards = totalRewards.add(rewards);
            }

        }

        return totalRewards;
    }

    /**
     * @dev nft Last time to receive proceeds
     */
    function getNftCheckpoint(uint256 tokenId) public view returns(uint256) {
        return nfts[tokenId].checkpoint;
    }

    /**
     * @dev nft Proceeds received
     */
    function getNftReceivedRewardTotal(uint256 tokenId) public view returns(uint256) {
        return nfts[tokenId].total;
    }

    /**
     * @dev Get nft current generated revenue
     */
    function getNftAvailable(uint256 tokenId) public view returns(uint256) {
        return getNftReceivedRewardTotal(tokenId).add(getNftRewards(tokenId));
    }

    /**
     * @dev nft current level
     */
    function tokenLevel(uint256 tokenId) public view returns(uint256){
        return IBasicNFT(basicNft).tokenLevel(tokenId);
    }

    /**
     * @dev nft full reward value
     */
    function getNftTotalRewards(uint256 tokenId) public view returns(uint256){
                
        uint256 _total = getNftTotalRecords(tokenId);

        return _total.mul(2);
    }

    /**
     * @dev nft Specifies the indexed records
     */
    function getNftRecordInfo(uint256 tokenId, uint256 index) public view returns(uint256, uint256, uint256) {
        NFT memory nftData = nfts[tokenId];

        return (nftData.records[index].amount, nftData.records[index].rewards, nftData.records[index].start);
    }

    /**
     * @dev nft Number of records
     */
    function getNftAmountOfRecords(uint256 tokenId) public view returns(uint256) {
        return nfts[tokenId].records.length;
    }

    /**
     * @dev nft Total number of inputs recorded
     */
    function getNftTotalRecords(uint256 tokenId) public view returns(uint256) {
        NFT memory nftData = nfts[tokenId];

        uint256 amount;

        for (uint256 i = 0; i < nftData.records.length; i++) {
            amount = amount.add(nftData.records[i].amount);
        }

        return amount;
    }

    /**
     * @dev nft Total amount already collected in the record
     */
    function getNftTotalClaim(uint256 tokenId) public view returns(uint256) {
        NFT memory nftData = nfts[tokenId];

        uint256 amount;

        for (uint256 i = 0; i < nftData.records.length; i++) {
            amount = amount.add(nftData.records[i].rewards);
        }

        return amount;
    }
    

}