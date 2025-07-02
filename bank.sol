// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NativeTokenVault {
    mapping(address => uint256) private balances;

    // 입금, 사용자가 value로 넣은 금액만큼 payable을 통해 ETH반환
    receive() external payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
    }

    // 조회
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // 출금
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // 전체 컨트랙트 보유 ETH 조회 (optional)
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
