// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IFundingRecipient {
    function complete() external payable;
    
  
    function completed() external view returns (bool);
}


contract CrowdFund {
    
    error NotOpenToWithdraw();
    
    
    error WithdrawTransferFailed(address to, uint256 amount);
    
   
    error TooEarly(uint256 deadline, uint256 currentTimestamp);
    
   
    error AlreadyCompleted();
    
    
    IFundingRecipient public fundingRecipient;
    
    bool public openToWithdraw;
    
   
    uint256 public deadline = block.timestamp + 69 seconds;
    
  
    uint256 public constant threshold = 1 ether;
    
    mapping(address => uint256) public balances;
    
   
    event Contribution(address, uint256);
    
   
    modifier notCompleted() {
        if (fundingRecipient.completed()) revert AlreadyCompleted();
        _;
    }
    
    
    constructor(address _fundingRecipient) {
        fundingRecipient = IFundingRecipient(_fundingRecipient);
    }
   
     
    function contribute() public payable notCompleted {
        balances[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);
    }
    
    
    function withdraw() public notCompleted {
        if (!openToWithdraw) revert NotOpenToWithdraw();
        
        uint256 balance = balances[msg.sender];
        
        balances[msg.sender] = 0;
        
        (bool success,) = msg.sender.call{value: balance}("");
        
        if (!success) revert WithdrawTransferFailed(msg.sender, balance);
    }
    
   
    function execute() public notCompleted {
      
        if (block.timestamp <= deadline) {
            revert TooEarly(deadline, block.timestamp);
        }
        
     
        if (address(this).balance >= threshold) {
           
            fundingRecipient.complete{value: address(this).balance}();
        } else {
       
            openToWithdraw = true;
        }
    }
    
    
    function timeLeft() public view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }
    
    receive() external payable {
        contribute();
    }
}
