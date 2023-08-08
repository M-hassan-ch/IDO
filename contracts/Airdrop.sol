// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// decimals issue
// int values >=

contract Airdrop is Pausable, Ownable {
    bool public _looslyCoupled;
    IERC20 public _tokenContract;
    address public _tokenHolder;

    int public _totalTokensForAirdrop;
    int public _distributedTokens;
    int public _rewardRate;
    uint public _decimals;

    // constructor() {
        
    // }

    function updateRewardRate(int rate) public onlyOwner{
        require(rate > 0, "Airdrop: Invalid reward rate");
        _rewardRate = rate;
    }

    function distributeTokens(address[] calldata users, uint[] calldata points) public onlyOwner{
        require(users.length == points.length, "Airdrop: Different lengths of user and point array");
        require(calculateTotalReward(points) + _distributedTokens <= _totalTokensForAirdrop, "Airdrop: Dont have sufficient tokens to distribute");
        
        isValidUserAddress(users);

        for (uint i; i < users.length; i++){
            int rewardEarnePerUser = (int(points[i]) * _rewardRate);

            if (_looslyCoupled){
                _tokenContract.transferFrom(_tokenHolder, users[i], uint(rewardEarnePerUser * int(10 ** _decimals)));
            }
            else{
                bytes memory payload = abi.encodeWithSignature("mint(address,uint256)", users[i], uint(rewardEarnePerUser * int(10 ** _decimals)));

                (bool success, ) = _tokenHolder.call(payload);
                
                require(success, "Airdrop: Function call failed");
            }

           _distributedTokens += rewardEarnePerUser * int(10 ** _decimals);
        }
    }

    function calculateTotalReward(uint[] calldata points) public view onlyOwner returns(int){
        int totalReward;
        
        for(uint i; i < points.length; i++){
            totalReward += int(points[i]) * _rewardRate;
        }

        return totalReward;
    }

    function isValidUserAddress(address[] calldata users) private pure {
        for (uint i; i < users.length; i++){
            require(users[i] == address(0), "Airdrop: Got invalid user address");
        }
    }

}