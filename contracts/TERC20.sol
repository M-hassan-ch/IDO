// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// make presale contract to call transferFrom
contract TERC20 is ERC20, ERC20Burnable, Pausable, Ownable {
    address public _preSaleContract;
    uint public _maxSupply;
    uint public _supplyForPreSale;

    constructor(
        string memory name,
        string memory symbol,
        // address preSaleContract,
        uint maxSupply
    ) ERC20(name, symbol) {
        // updatePreSaleContract(preSaleContract);
        updateMaxSupply(maxSupply);
    }

    modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == _preSaleContract);
        _;
    }

    function mint(address to, uint256 amount) public onlyAllowed whenNotPaused {
        uint amountWithDecimals = amount * (10 ** decimals());

        maxSupplyIsNotReached(amountWithDecimals);

        _mint(to, amountWithDecimals);
    }

    function forceMint(address to, uint256 amount) public onlyOwner {
        uint amountWithDecimals = amount * (10 ** decimals());
        _mint(to, amountWithDecimals);
    }

    function maxSupplyIsNotReached(uint tokenToMint) private view {
        require(
            totalSupply() + tokenToMint <= _maxSupply * (10 ** decimals()),
            "ERC20: Max-Supply is reached"
        );
    }

    function findValueFromPercentage(
        uint percentage,
        uint totalAmount
    ) private pure returns (uint) {
        return (percentage * totalAmount) / 100;
    }

    function updatePreSaleContract(
        address preSaleContract
    ) public onlyOwner whenNotPaused {
        require(
            preSaleContract.code.length > 0,
            "ERC20: Invalid pre-sale contract address"
        );
        _preSaleContract = preSaleContract;
    }

    function updateMaxSupply(uint maxSupply) public onlyOwner whenNotPaused {
        require(maxSupply > 0, "ERC20: Max-supply should be > 0");
        _maxSupply = maxSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
