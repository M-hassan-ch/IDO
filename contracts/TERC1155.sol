// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Approve

contract TERC1155 is
    ERC2981,
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    string public name;
    using Strings for uint256;

    address public _preSaleContract;

    mapping(uint => uint) public _maxSupply;

    // 1 : NIN-EI => 142858
    // 2 : NIN-ES =>  //
    // 3 : NIN-CC =>  //
    // 4 : NIN-E  =>  //
    // 5 : NIN-M  =>  //
    // 6 : NIN-R  =>  //
    // 7 : NIN-N  =>  //

    modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == _preSaleContract);
        _;
    }

    constructor(
        string memory collectionName,
        string memory baseURI_
    ) ERC1155(baseURI_) {
        updateCollectionName(collectionName);

        _maxSupply[1] = 142858;
        _maxSupply[2] = 142858;
        _maxSupply[3] = 142858;
        _maxSupply[4] = 142858;
        _maxSupply[5] = 142858;
        _maxSupply[6] = 142858;
        _maxSupply[7] = 142858;

        _setDefaultRoyalty(msg.sender, 25);
    }

    function mint(
        address account,
        uint256 id,
        uint256 copies // , uint256 id, uint256 amount, bytes memory data
    ) public onlyAllowed {
        checkNFTExists(id);
        maxSupplyIsNotReached(id, copies);

        _mint(account, id, copies, "");
    }

    function withdrawAmount(uint amount) public onlyOwner {
        require(amount > 0, "Main: amount is 0");
        require(amount <= address(this).balance, "Main: Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function _feeDenominator() internal pure override returns (uint96) {
        return 100;
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function updateApproval(
        address owner,
        address operator,
        bool appproved
    ) public onlyOwner {
        require(owner != address(0), "TERC1155: Owner address is null");
        require(operator != address(0), "TERC1155: Operator address is null");

        _setApprovalForAll(owner, operator, appproved);
    }

    function updateCollectionName(
        string memory collectionName
    ) public onlyOwner {
        name = collectionName;
    }

    function updatePresaleContract(address presaleAddr) public onlyOwner {
        require(
            presaleAddr.code.length > 0,
            "TERC1155: Invalid presale contract"
        );
        _preSaleContract = presaleAddr;
    }

    function updateMaxSupply(uint tokenId, uint supply) public onlyOwner {
        require(supply > totalSupply(tokenId), "TERC1155: Invalid supply");
        _maxSupply[tokenId] = supply;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                bytes.concat(
                    bytes(super.uri(0)),
                    bytes(tokenId.toString()),
                    ".json"
                )
            );
    }

    function maxSupplyIsNotReached(
        uint tokenId,
        uint copiesToMint
    ) private view {
        require(
            totalSupply(tokenId) + copiesToMint <= _maxSupply[tokenId],
            "TERC1155: Max-Supply of NFT is reached"
        );
    }

    function checkNFTExists(uint tokenId) private view {
        require(_maxSupply[tokenId] > 0, "TERC1155: NFT don't exists");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
