// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CGGToken is ERC20{
    address public admin;
    mapping(address => bool) whitelistedAddresses;
    mapping(address => bool) blacklistedAddresses;

    constructor() ERC20("CGG TOKEN", "CGG") {
        // Init supply: 100 billion
        _mint(msg.sender, 100000000000 * 10 ** 18); 
        admin = msg.sender;
    }

    modifier onlyAdmin() {
      require(msg.sender == admin, "Caller is not the admin");
      _;
    }

    // Admin can mint more tokens
    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }

    // Admin can burn more tokens
    function burn(uint amount) external {
        require(msg.sender == admin, "Only admin can burn");
        _burn(msg.sender, amount);
    }

    function addWhitelistUser(address _addressToWhitelist) public onlyAdmin {
      whitelistedAddresses[_addressToWhitelist] = true;
    }

    function addBlacklistUser(address _addressToBlacklist) public onlyAdmin {
      blacklistedAddresses[_addressToBlacklist] = true;
    }

    function verifyWhitelistedUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    function verifyBlacklistedUser(address _blacklistedAddress) public view returns(bool) {
      bool userIsBlacklisted = blacklistedAddresses[_blacklistedAddress];
      return userIsBlacklisted;
    }


    function transfer(address recipient, uint256 amount) public virtual override(ERC20) returns(bool) {

        require(!blacklistedAddresses[msg.sender], "Blacklisted users");

        if (whitelistedAddresses[msg.sender]) {
            _transfer(msg.sender, recipient, amount);
        } else {
          uint256 allowedTransferTime = 1668428268;
          require(block.timestamp >= allowedTransferTime, "Non-whitelisted user only can transfer token after 1668428268");
          _transfer(msg.sender, recipient, amount);
        }
        return true;
    }

        function pullFunds(address tokenAddress_) onlyAdmin external {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }
}