// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wallet {
    string constant nameToken = "MyWalletToken";
    string constant symbolToken = "MW";
    uint8 constant decimalsToken = 0;
    address payable constant commissionOwner = payable(0x17F6AD8Ef982297579C203069C1DbfFE4348c372);
    uint8 commission = 1; //percents
    mapping(address => uint256) balanceOf; 
    mapping(address => mapping(address => uint256)) tokensBalance;
    mapping(address => mapping(address => mapping(address => uint256))) tokensAllowance;
    event Transfer(address indexed from, address indexed to, uint256 eth);
    event ApprovalTokens(address indexed token, address indexed tokenOwner, address indexed spender, uint256 tokens);
    event TransferTokens(address indexed token, address indexed from, address indexed to, uint256 tokens);
    
    function changeCommission(uint8 newComm) external {
        require(msg.sender == commissionOwner, "Access is possible only for the owner");
        require(newComm < 100, "Incorrect parametr of commission");
        commission = newComm;
    }
    
    function depositEth() external payable  {
        balanceOf[msg.sender] += msg.value;
    }
    
    function transferEth(address to, uint256 amount) external {
        uint256 payment = amount * commission / 100;
        require( balanceOf[msg.sender] >= amount + payment, "insufficient funds");
        balanceOf[msg.sender] -= amount + payment;
        balanceOf[to] += amount;
        commissionOwner.transfer(payment);
        emit Transfer(msg.sender, to, amount);
    }
    
    function withdrawFromAccaunt(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "insufficient funds");
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    function ethBalanceOf(address owner) external view returns(uint256) {
        return balanceOf[owner];
    }

    function approve( address token, address spender, uint256 amount ) external {
        tokensAllowance[token][msg.sender][spender] = amount;
        emit ApprovalTokens(token, msg.sender, spender, amount);
    }
    
    function deposit(IERC20 token, uint256 amount) external  {
        assert(token.transferFrom(msg.sender, address(this), amount));
        tokensBalance[address(token)][msg.sender] += amount; 
    }
    
    function transferTokens(address token, address to, uint256 amount) external {
        require(tokensBalance[token][msg.sender] >= amount, "not enough tokens");
        require(tokensBalance[token][to] + amount >= amount);
        tokensBalance[token][msg.sender] -= amount;
        tokensBalance[token][to] += amount;
        emit TransferTokens(token, msg.sender, to, amount);
    }
    
    function transferFrom(IERC20 token, address owner, address to, uint256 amount) external {
        address tokenAddress = address(token);
        require(tokensAllowance[tokenAddress][owner][msg.sender] >= amount, "Not enough allowed");
        require(tokensBalance[tokenAddress][owner] >= amount, "not enough tokens");
        tokensAllowance[tokenAddress][owner][msg.sender] -= amount;
        tokensBalance[tokenAddress][owner] -= amount;
        tokensBalance[tokenAddress][to] += amount;
        emit TransferTokens(tokenAddress, owner, to, amount);
    }
    
    function withdraw(IERC20 token, uint256 amount) external {
        require(tokensBalance[address(token)][msg.sender] >= amount);
        tokensBalance[address(token)][msg.sender] -= amount;
        assert(token.transfer(msg.sender, amount));
    }
    
    function allowance(address token, address owner, address delegate) external view returns(uint256) {
        return tokensAllowance[token][owner][delegate];
    }
    
    function tokensBalanceOf(address token, address owner) external view returns(uint256) {
        return tokensBalance[token][owner];
    }
}