// License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is ERC20, ERC20Pausable, Ownable, ReentrancyGuard {

    struct UserInfo{
        bool contributed;
        uint256 contributedAmount;
        bool firstClaimable;
        bool secondClaimable;
    }
    mapping(address => UserInfo) public contributors;
    uint256 public numberOfContributors = 0;
    uint256 public totalContributedAmount = 0;
    ERC20 public currToken;
    uint256 public ICOStartTime = 1666695689;
    uint256 public ICOEndTime = 1669374089;
    uint256 public maxTotalContributionAmount = 0.1 ether;
    uint256 public singleContributionAmountUnit = 0.01 ether;

    // constructor
    constructor() ERC20("ICO", "ICO") {
        _pause();
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ICO: not eoa");
        _;
    }

    function setICOToken(address currTokenAddress) whenPaused public onlyOwner {
        currToken = ERC20(currTokenAddress);
    }

    function pause() onlyOwner external {
        _pause();
    }

    function unpause() onlyOwner external {
        _unpause();
    }

    /**
      * @dev function to buy token with ether
    */
    function contribute() payable nonReentrant onlyEOA external returns (bool success) {
        require(block.timestamp>=ICOStartTime && block.timestamp<=ICOEndTime,
            "ICO: not in ICO time");
        require(totalContributedAmount + msg.value <= maxTotalContributionAmount,
            'ICO: max contribution amount reached');
        require(msg.value <= maxTotalContributionAmount,
            'ICO: cannot exceed maxTotalContributionAmount ');
        require((msg.value / (singleContributionAmountUnit*100)/100) % 10 == 0,
            'ICO: contribution should be Contribution Unit or the times of Contribution Unit');

        UserInfo storage user = contributors[msg.sender];

//        require(user.contributedAmount+msg.value <= maxTotalContributionAmount,
//            "ICO: max contribution amount 1 BNB per user reached'");

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

    function isContributor(address candidate_) public view returns (bool) {
        UserInfo storage user = contributors[candidate_];
        return user.contributed;
    }

}
