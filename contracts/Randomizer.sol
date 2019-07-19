pragma solidity ^0.5.9;

contract Randomizer {

    function init(uint num) public returns(uint){
        uint result = uint(keccak256(abi.encodePacked(now, blockhash(block.number%num)))) % num;
        if(result == 0) return 1;
        return result;
    }
}
