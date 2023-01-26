// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Utils/Context.sol";
import "./FLE.sol";

contract FILL is Context {
    mapping(address => uint256) private balances;
    mapping(address => uint256) private borrows;
    address private _owner;
    FLE _tokenFLE;

    event Deposit(address indexed accountAddress, uint256 amount);
    event Borrow(address indexed accountAddress, uint256 amount);

    constructor(address fleAddress) {
        _tokenFLE = FLE(fleAddress);
        _owner = _msgSender();
    }

    function deposit(uint256 amount) public payable returns (uint256) {
        require(msg.value >= amount, "invalid amount");

        _tokenFLE.mint(_msgSender(), amount);
        return _tokenFLE.balanceOf(_msgSender());
    }

    function withdraw(uint256 amount) public returns (uint256) {

        _tokenFLE.burn(_msgSender(), amount);
        payable(_msgSender()).transfer(amount);
        return _tokenFLE.balanceOf(_msgSender());
    }

    function balanceOf() public view returns (uint256) {
        return _tokenFLE.balanceOf(_msgSender());
    }

    modifier noArrears(address _addr) {
        require(borrows[_addr] == 0, "need to pay first");
        _;
    }
    modifier haveArrears(address _addr) {
        require(borrows[_addr] > 0, "no need to pay");
        _;
    }

    function borrow(uint256 amount)
        public
        noArrears(_msgSender())
        returns (uint256)
    {
        borrows[_msgSender()] = amount;
        return borrows[_msgSender()];
    }

    function payback(uint256 amount) public haveArrears(_msgSender()) {
        require(borrows[_msgSender()] == amount, "amount not equal borrow");
        delete borrows[_msgSender()];
    }

    function depositsBalance() public view returns (uint256) {
        return address(this).balance;
    }

}
