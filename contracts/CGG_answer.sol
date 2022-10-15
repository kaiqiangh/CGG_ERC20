// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract CGG is AccessControlEnumerable, ERC20Burnable, ERC20Pausable, ERC20Votes {

    address _fundAddress;
    address public _uniswapPair;
    uint256 public launchedAt = 0;
    mapping (address => bool) private _blackList;
    mapping (address => bool) private _whiteList;
    bool public swapAndLiquifyEnabled = false;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public maxSupply = 10 ** 12 * (10 ** 18);
    string private constant TOKEN_NAME = "CGG";

    uint256 public tradingEnabledTimestamp = 1628258400;

    constructor() ERC20(TOKEN_NAME, "CGG") ERC20Permit(TOKEN_NAME) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _fundAddress = _msgSender();
        _whiteList[_msgSender()] = true;
    }

    function transferAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, account);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= maxSupply, "ERC20: total supply overflowing");
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function pause() external virtual onlyRole(PAUSER_ROLE)  {
        _pause();
    }

    function unpause() external virtual onlyRole(PAUSER_ROLE)  {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /*
     * @dev Pull out all balance of token or BNB in this contract. When tokenAddress_ is 0x0, will transfer all BNB to the admin owner.
     */
    function pullFunds(address tokenAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */

    function transfer(address recipient, uint256 amount) public virtual override(ERC20) returns (bool) {
        require(!_blackList[_msgSender()], "ERC20: sender in blacklist");
        if(_whiteList[recipient] || _whiteList[_msgSender()]){
            _transfer(_msgSender(), recipient, amount);
        }else {
            require(block.timestamp>=tradingEnabledTimestamp, "ERC20: Enable trading");
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20) returns (bool) {
        require(!_blackList[sender], "ERC20: sender in blacklist");
        if(_whiteList[recipient] || _whiteList[sender]){
            _transfer(sender, recipient, amount);
        }else {
            require(block.timestamp>=tradingEnabledTimestamp, "ERC20: Enable trading");
            _transfer(sender, recipient, amount);
        }
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function setUniswapPair(address uniswapPair) external onlyRole(DEFAULT_ADMIN_ROLE){
        _uniswapPair = uniswapPair;
    }

    function addToBlackList(address account, bool isBlackList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _blackList[account] = isBlackList;
    }

    function addToWhiteList(address account, bool isWhiteList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _whiteList[account] = isWhiteList;
    }

    function openTrading() external onlyRole(DEFAULT_ADMIN_ROLE) {
        launchedAt = block.number;
        swapAndLiquifyEnabled = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAndLiquifyEnabled = _enabled;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }
}