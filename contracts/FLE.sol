// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";

contract FLE is ERC20 {
    address _owner;
    mapping(address => bool) manageAddresses;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _owner = msg.sender;
        manageAddresses[_owner] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    modifier isManager(address _address) {
        require(manageAddresses[_address], "You need to be manager");
        _;
    }

    function mint(address account, uint256 amount)
        public
        isManager(msg.sender)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        public
        isManager(msg.sender)
    {
        _burn(account, amount);
    }

    function addUser(address user) public onlyOwner {
        manageAddresses[user] = true;
    }

    function removeUser(address user) public onlyOwner {
        delete manageAddresses[user];
    }

    function verifyUser(address _address) public view returns (bool) {
        return manageAddresses[_address];
    }
}
