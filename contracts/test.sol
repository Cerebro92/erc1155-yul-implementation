// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract TestString {
    string public uri;

    uint public myint = 0x68656c6c6f000000000000000000000000000000000000000000000000000000;

    constructor() {}

    function store(string memory uri_) public {
        uri = uri_;
    }

    function toString() public view returns (string memory) {
        return string(abi.encode(myint));
    }
}
