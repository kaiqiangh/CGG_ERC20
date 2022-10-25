// License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICOGoRunner is ERC20, ERC20Pausable, Ownable, ReentrancyGuard {

    struct UserInfo{
        bool contributed;
        uint256 contributedAmount;
        bool firstClaimable;
        bool secondClaimable;
    }
    mapping(address => UserInfo) public contributors;
    uint256 public totalClaimableAmount = 0;
    uint256 public unlockTimes = 0;
    uint256 public numberOfContributors = 0;
    uint256 public totalContributedAmount = 0;
    ERC20 public currToken;

    // constructor
    constructor() ERC20("ICO", "ICO") {
        _pause();
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ICO: not eoa");
        _;
    }

    /**
      * @dev function to buy token with ether
    */
    function buy() payable nonReentrant onlyEOA external returns (bool success) {
        require(block.timestamp>=1648900800 && block.timestamp<=1648987200, "ICO: not in ICO time");
        require(totalContributedAmount + msg.value <= 100 ether, 'ICO: max contribution amount 100 BNB reached');
        require(msg.value >= 0.1 ether && msg.value <= 1 ether, 'ICO: need to be between 0.1 and 1 BNB');
        require(msg.value*10%(1 ether) == 0, 'ICO: need to be rounded');
        UserInfo storage user = contributors[msg.sender];
        require(user.contributedAmount+msg.value<=1 ether, "ICO: max contribution amount 1 BNB per user reached'");
        if(!user.contributed){
            user.contributed = true;
            user.firstClaimable = true;
            user.secondClaimable = true;
            numberOfContributors++;
            user.contributedAmount = msg.value;
        }else{
            user.contributedAmount += msg.value;
        }
        totalContributedAmount += msg.value;
        return true;
    }

    function claim() whenNotPaused onlyEOA external returns (bool success) {
        require(isContributor(msg.sender), "ICO: never contributed");
        require(isUserClaimable(msg.sender), "ICO: already withdrawn");
        require(totalClaimableAmount != 0, "ICO: not supplied");
        UserInfo storage user = contributors[msg.sender];
        currToken.transfer(msg.sender, totalClaimableAmount * (user.contributedAmount*10/(1 ether)) / (totalContributedAmount*10/(1 ether)));
        updateUserClaimable(msg.sender, false);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /*
     * @dev Pull out all balance of token or BNB in this contract. When tokenAddress_ is 0x0, will transfer all BNB to the admin owner.
     */
    function pullFunds(address tokenAddress_) public onlyOwner returns (bool success) {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
        return true;
    }

    function pause() onlyOwner external {
        _pause();
    }

    function unpause() onlyOwner external {
        _unpause();
    }

    function isContributor(address candidate_) public view returns (bool) {
        UserInfo storage user = contributors[candidate_];
        return user.contributed;
    }

    function setCurrToken(address currTokenAddress) whenPaused public onlyOwner {
        currToken = ERC20(currTokenAddress);
    }

    function setTotalClaimableAmount(uint256 totalClaimableAmount_) whenPaused public onlyOwner {
        totalClaimableAmount = totalClaimableAmount_;
    }

    function setUnlockTimes(uint256 unlockTimes_) whenPaused public onlyOwner {
        unlockTimes = unlockTimes_;
    }

    function updateUserClaimable(address sender, bool claimable) internal {
        UserInfo storage user = contributors[sender];
        if(unlockTimes == 1){
            user.firstClaimable = claimable;
        }else if(unlockTimes == 2){
            user.secondClaimable = claimable;
        }
    }

    function isUserClaimable(address candidate_) public view returns (bool) {
        UserInfo storage user = contributors[candidate_];
        if(unlockTimes == 1){
            return user.firstClaimable;
        }else if(unlockTimes == 2){
            return user.secondClaimable;
        }
        return false;
    }
}
