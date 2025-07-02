// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECDSAVoting {
    address public owner;

    // 투표 가능한 주소 관리
    mapping(address => bool) public isVoter;

    // 안건 구조체
    struct Proposal {
        uint256 id;
        address to;
        uint256 value;
        bytes data;
        uint256 createdAt;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // 각 주소가 투표 했는지 안했는지
    }

    mapping(uint256 => Proposal) private proposals;
    uint256 public nextProposalId;

    event ProposalCreated(uint256 id, address to, uint256 value, bytes data);
    event Voted(uint256 id, address signer, bool support);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor(address[] memory voters) {
        owner = msg.sender;
        for (uint256 i = 0; i < voters.length; i++) {
            isVoter[voters[i]] = true;
        }
    }

    // 안건 추가 onlyOwner로 제한
    function createProposal(address to, uint256 value, bytes memory data) external onlyOwner {
        uint256 id = nextProposalId++;
        Proposal storage p = proposals[id];
        p.id = id;
        p.to = to;
        p.value = value;
        p.data = data;
        p.createdAt = block.timestamp;

        emit ProposalCreated(id, to, value, data);
    }

    // 서명 기반 투표
    function vote(
        uint256 id,
        bool support,
        bytes memory signature
    ) external {
        Proposal storage p = proposals[id];
        require(p.createdAt != 0, "Proposal does not exist");

        // 메시지 다이제스트 생성
        bytes32 messageHash = keccak256(abi.encodePacked(id, p.to, p.value, p.data));
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(messageHash);

        // 서명으로부터 signer 복구
        address signer = recoverSigner(ethSignedMessageHash, signature);

        require(isVoter[signer], "Not an authorized voter");
        require(!p.hasVoted[signer], "Already voted");

        // 투표 기록
        p.hasVoted[signer] = true;
        if (support) {
            p.forVotes++;
        } else {
            p.againstVotes++;
        }

        emit Voted(id, signer, support);
    }

    function getProposalResult(uint256 id) external view returns (
        address to,
        uint256 value,
        uint256 forVotes,
        uint256 againstVotes
    ) {
        Proposal storage p = proposals[id];
        return (p.to, p.value, p.forVotes, p.againstVotes);
    }

    // 서명 형식으로 메시지를 변환
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // 유틸: 서명으로부터 서명자 주소 복구
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}
