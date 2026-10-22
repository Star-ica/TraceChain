// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// Supply-chain provenance: approved participants register products and record every custody change and update.
contract TraceChain {
    address public admin = msg.sender;
    struct Participant { string name; string role; bool active; }
    struct Product { string name; string batch; string origin; address creator; address holder; uint256 createdAt; bool delivered; }
    struct Step { address by; string location; string status; string note; uint256 time; }

    mapping(address => Participant) public participants;
    address[] private pList;
    Product[] private products;
    mapping(uint256 => Step[]) private trail;
    mapping(address => uint256[]) private byParticipant;
    mapping(address => mapping(uint256 => bool)) private seen;

    event ParticipantAdded(address indexed who, string name, string role);
    event ParticipantRemoved(address indexed who);
    event ProductRegistered(uint256 indexed id, address indexed creator);
    event StepAdded(uint256 indexed id, address indexed by, string status);
    event CustodyTransferred(uint256 indexed id, address indexed from, address indexed to);

    modifier onlyAdmin() { require(msg.sender == admin, "admin only"); _; }
    modifier onlyActive() { require(participants[msg.sender].active, "not an approved participant"); _; }
    modifier onlyHolder(uint256 id) {
        require(id < products.length, "not found");
        require(products[id].holder == msg.sender && !products[id].delivered, "not current holder");
        _;
    }

    function transferAdmin(address a) external onlyAdmin { require(a != address(0), "zero"); admin = a; }

    function addParticipant(address a, string calldata name, string calldata role) external onlyAdmin {
        require(a != address(0) && bytes(name).length > 0, "invalid");
        if (bytes(participants[a].name).length == 0) pList.push(a);
        participants[a] = Participant(name, role, true);
        emit ParticipantAdded(a, name, role);
    }
    function removeParticipant(address a) external onlyAdmin { participants[a].active = false; emit ParticipantRemoved(a); }
    function participantCount() external view returns (uint256) { return pList.length; }
    function participantAt(uint256 i) external view returns (address, string memory, string memory, bool) {
        address a = pList[i]; Participant storage p = participants[a]; return (a, p.name, p.role, p.active);
    }

    function _log(uint256 id, string memory location, string memory status, string memory note) internal {
        trail[id].push(Step(msg.sender, location, status, note, block.timestamp));
        emit StepAdded(id, msg.sender, status);
    }
    function _touch(address a, uint256 id) internal {
        if (!seen[a][id]) { seen[a][id] = true; byParticipant[a].push(id); }
    }

    function registerProduct(string calldata name, string calldata batch, string calldata origin) external onlyActive returns (uint256 id) {
        require(bytes(name).length > 0, "name required");
        id = products.length;
        products.push(Product(name, batch, origin, msg.sender, msg.sender, block.timestamp, false));
        _touch(msg.sender, id);
        _log(id, origin, "Registered", "Product registered");
        emit ProductRegistered(id, msg.sender);
    }
    function addUpdate(uint256 id, string calldata location, string calldata status, string calldata note) external onlyHolder(id) {
        _log(id, location, status, note);
    }
    function transferCustody(uint256 id, address to, string calldata location, string calldata status, string calldata note) external onlyHolder(id) {
        require(participants[to].active && to != msg.sender, "invalid recipient");
        products[id].holder = to;
        _touch(to, id);
        _log(id, location, status, note);
        emit CustodyTransferred(id, msg.sender, to);
    }
    function markDelivered(uint256 id, string calldata location, string calldata note) external onlyHolder(id) {
        products[id].delivered = true;
        _log(id, location, "Delivered", note);
    }

    function productCount() external view returns (uint256) { return products.length; }
    function getProduct(uint256 id) external view returns (string memory, string memory, string memory, address, address, uint256, bool) {
        require(id < products.length, "not found");
        Product storage p = products[id];
        return (p.name, p.batch, p.origin, p.creator, p.holder, p.createdAt, p.delivered);
    }
    function stepCount(uint256 id) external view returns (uint256) { return trail[id].length; }
    function getStep(uint256 id, uint256 i) external view returns (address, string memory, string memory, string memory, uint256) {
        Step storage s = trail[id][i]; return (s.by, s.location, s.status, s.note, s.time);
    }
    function productsOf(address a) external view returns (uint256[] memory) { return byParticipant[a]; }
}
