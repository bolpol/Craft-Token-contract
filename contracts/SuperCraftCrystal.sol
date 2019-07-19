pragma solidity ^0.5.9;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol';
import '../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol';

contract SuperCraftCrystal is ERC721Full, ERC721Mintable {

    address public proxyToken;

    constructor() ERC721Full("Super Craft Crystal for Craft Tokens system", "SSYNCR") public {
        proxyToken = msg.sender;
    }

    modifier onlyProxy() {
        require(proxyToken, "Ownable: caller is not the owner");
        _;
    }

    function issue(address to, uint num) external onlyProxy returns(bool) {
        for(uint i=0; i<num; i++) {
            _mint(to, totalSupply() + 1);
        }
        return true;
    }
}