// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingContract {
    // 계약 배포자(소유자)
    address public owner;

    // 안건 구조체 정의
    struct Proposal {
        uint256 id;              // 안건 ID
        string description;      // 안건 설명
        uint256 createdAt;       // 생성 시각(타임스탬프)
        uint256 forVotes;        // 찬성 투표 수
        uint256 againstVotes;    // 반대 투표 수
        bool executed;           // 결과가 처리되었는지 여부 (추후 확장용)
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;  // 다음 안건 ID

    mapping(address => bool) public isVoter;

    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // 오직 배포자만 호출 가능하도록 제한
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this.");
        _;
    }

    // 오직 투표 자격 있는 주소만 호출 가능
    modifier onlyVoter() {
        require(isVoter[msg.sender], "Not authorized to vote.");
        _;
    }

    // 생성자: 배포 시 초기 투표자 설정
    constructor(address[] memory initialVoters) {
        owner = msg.sender;
        for (uint256 i = 0; i < initialVoters.length; i++) {
            isVoter[initialVoters[i]] = true;
        }
    }

    // 배포자만 새로운 투표자를 추가 가능
    function addVoter(address voter) external onlyOwner {
        isVoter[voter] = true;
    }

    // 배포자만 안건을 생성할 수 있음
    function createProposal(string memory description) external onlyOwner {
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            description: description,
            createdAt: block.timestamp,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });
        nextProposalId++;
    }

    // 투표 함수: 투표자만, 5분 내에 1회 투표 가능
    function vote(uint256 proposalId, bool support) external onlyVoter {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.createdAt + 5 minutes, "Voting period has ended.");
        require(!hasVoted[proposalId][msg.sender], "Already voted.");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
    }

    // 결과 확인 함수: 5분 경과 후 호출 가능
    function getResult(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.createdAt + 5 minutes, "Voting period not ended yet.");

        if (proposal.forVotes > proposal.againstVotes) {
            return "Proposal Passed";
        } else if (proposal.forVotes < proposal.againstVotes) {
            return "Proposal Rejected";
        } else {
            return "Tie";
        }
    }
}
