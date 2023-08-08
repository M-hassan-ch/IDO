// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//transfer funds 
//update functions
// withdraw unused tokens
// decimals issue

contract Presale is Pausable, Ownable {
    
    bool public _looslyCoupled;
    IERC20 public _tokenContract;
    address public _tokenHolder;

    uint256 public _totalTokensForPreSale;
    uint public _soldTokens;
    uint256 public _preSalePrice;
    
    uint256 public _preSaleStartDate;
    uint256 public _preSaleEndDate;
    uint public _cliffPeriod;

    uint256 public _minInvestment;
    uint256 public _maxInvestment;

    mapping(address => uint256) public _investments;
    mapping(address => uint256) public _tokensPurchased;

    ////////////////////////////////////////////

    uint256 public _firstReleasePercent;
    uint256 public _releasePercent;
    
    uint256 public _releasePeriod;

    mapping(address => uint256) public _releasedTokens;
     mapping(address => uint256) public _transferedTokens;
    mapping(address => uint256) public _lastTimeTokenReleased;

    constructor(
        address erc20Addr,
        address tokenHolder
    ) {
        _tokenContract = IERC20(erc20Addr);
        _tokenHolder = tokenHolder;
    }

    function buyTokenInCrypto() public payable {
        require(block.timestamp >= _preSaleStartDate, "Presale: Presale is not started");
        require(block.timestamp <= _preSaleEndDate, "Presale: Presale is ended");
        require(msg.value >= _minInvestment && msg.value <= _maxInvestment, "Presale: Insufficient amount sent");

        uint tokenEarned = msg.value / _preSalePrice;
        uint price = tokenEarned * _preSalePrice;
        uint remainingPrice = msg.value - price;

        require(tokenEarned + _soldTokens <= _totalTokensForPreSale, "Presale: Don't have enough available tokens");

        _investments[msg.sender] += price;
        _tokensPurchased[msg.sender] += tokenEarned;
        _soldTokens += tokenEarned;

        if (remainingPrice > 0){
            payable(msg.sender).transfer(remainingPrice);
        }
    }

    function buyTokenInFiat(uint tokenToBuy) public onlyOwner{
        require(block.timestamp >= _preSaleStartDate, "Presale: Presale is not started");
        require(block.timestamp <= _preSaleEndDate, "Presale: Presale is ended");
        
        require(tokenToBuy + _soldTokens <= _totalTokensForPreSale, "Presale: Don't have enough available tokens");

        _tokensPurchased[msg.sender] += tokenToBuy;
        _soldTokens += tokenToBuy;
    }

    // user centric release tokens || owner based release tokens
    function releaseTokens() public {
        uint tokensToRelease;
        uint currentTimestamp = block.timestamp;

        require(_tokensPurchased[msg.sender] > 0, "Presale: Don't have any bought token");
        require(currentTimestamp >= _preSaleEndDate + _cliffPeriod, "Presale: Distribution is not started yet");

        if (_lastTimeTokenReleased[msg.sender] == 0){
            _lastTimeTokenReleased[msg.sender] =  _preSaleEndDate + _cliffPeriod + 1;
            tokensToRelease = findValueFromPercentage(_firstReleasePercent, _tokensPurchased[msg.sender]);
        }
        else {
            require(currentTimestamp >= _lastTimeTokenReleased[msg.sender] + _releasePeriod, "Presale: Vesting period is not over");
            
            _lastTimeTokenReleased[msg.sender] = _lastTimeTokenReleased[msg.sender] + _releasePeriod;
            tokensToRelease = findValueFromPercentage(_releasePercent, _tokensPurchased[msg.sender]);
        }

        uint availableForRelease = _tokensPurchased[msg.sender] - _releasedTokens[msg.sender];

        require(tokensToRelease <= availableForRelease, "Presale: Cannot release tokens more than purchased tokens");
            
        _releasedTokens[msg.sender] += tokensToRelease;
    }

    function claimToken() public {
        require(_releasedTokens[msg.sender] - _transferedTokens[msg.sender] > 0, "Presale: Don't have any sufficient balance to release");

        if (_looslyCoupled){
            _tokenContract.transferFrom(_tokenHolder, msg.sender, _releasedTokens[msg.sender]);
        }
        else{
            bytes memory payload = abi.encodeWithSignature("mint(address,uint256)", msg.sender, _releasedTokens[msg.sender]);

            (bool success, ) = _tokenHolder.call(payload);
            
           require(success, "Presale: Function call failed");
        }

        _transferedTokens[msg.sender] += _releasedTokens[msg.sender];
    }

    function withdrawAmount(uint amount) public onlyOwner{
        require(amount > 0, "Main: amount is 0");
        require(amount <= address(this).balance, "Main: Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function withdrawUnsoldTokens() public onlyOwner{
        
        uint remainingTokens = _totalTokensForPreSale - _soldTokens;

        require(remainingTokens > 0, "Presale: All tokens are sold");
        
        if (_looslyCoupled){
            _tokenContract.transferFrom(_tokenHolder, owner(), remainingTokens);
        }
        else{
            bytes memory payload = abi.encodeWithSignature("mint(address,uint256)", msg.sender, remainingTokens);

            (bool success, ) = _tokenHolder.call(payload);
            
           require(success, "Presale: Function call failed");
        }

        _soldTokens = _totalTokensForPreSale;
    }

    // check for updates is >= supplied amount
    // function updateTotalTokenForPresale(uint updatedSupply) public onlyOwner{
    //     _totalTokensForPreSale = updatedSupply;
    // }

    function updatePresalePrice(uint updatedPrice) public onlyOwner{
        _preSalePrice = updatedPrice;
    }

    function findValueFromPercentage(
        uint percentage,
        uint totalAmount
    ) private pure returns (uint) {
        return (percentage * totalAmount) / 100;
    }

}