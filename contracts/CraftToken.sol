pragma solidity ^0.5.9;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SuperCraftCrystal.sol";
import "./Randomizer.sol";


contract CraftToken is IERC20, ERC20Detailed, Ownable {
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Atomize(address indexed from, uint256 value);
    event Craft(address indexed from, uint256 value);

    SuperCraftCrystal public crystal;
    Randomizer public randomizer;

    uint256 public totalSupply;

    mapping (address => uint256) private _balances;
    mapping(address => mapping(address=> uint256)) private _allowances;
    mapping(address => bool) public frozenAccount;

    // пыль может торговаться внутри syncrafttoken exchange
    mapping (address => uint256) private _dust;
    mapping (address => uint256) private _energy;

    mapping (address => uint256) private _frozenPeriod;

    function dustOf(address _who) public returns (uint256) {
        return _dust[_who];
    }

    function energyOf(address _who) public returns (uint256) {
        return _energy[_who];
    }

    uint public atmzfee = 1000;

    function atomize(uint256 _amount) public {
        _balances[msg.sender] -= _amount * 10**uint(decimals);
        _dust[msg.sender] += _amount * atmzfee;
        _energy[msg.sender] = _amount;
        totalSupply -= _amount;
        event Atomize(msg.sender, _amount);
    }

    function craft(uint256 _amount) public {
        require(_energy[msg.sender] >= 1000);
        _energy[msg.sender] -= 1000;
        _dust[msg.sender] -= _amount * atmzfee * 10**uint(decimals);
        _balances[msg.sender] += _amount;
        event Craft(msg.sender, _amount);
    }

    function superCraft() public {
        require(_energy[msg.sender] >= 1000000);
        _energy[msg.sender] -= 1000000;
        uint _amount = _dust[msg.sender] -= _dust[msg.sender];
        _amount = _amount * 10**uint(decimals)/atmzfee;
        uint _ownerfee = _amount/15;
        _balances[owner] = _ownerfee;
        _balances[msg.sender] += _amount - _ownerfee;
        // + генерация уникльного токена
        crystal.issue(msg.sender, randomizer.init(4));
        event Craft(msg.sender, _amount);
    }

    constructor (
        uint256 initialSupply,
        string memory name,
        string memory symbol,
        uint8 decimals
    )
    public
    ERC20Detailed(
        'Craft Token | syncraft.io',
        'SYNCR',
        '18')
    {
        totalSupply = initialSupply*10**uint256(decimals);
        _balances[msg.sender] = totalSupply;
        crystal = new SuperCraftCrystal();
        randomizer = new Randomizer();
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(_balances[_from] >=_value);
        require(_balances[_to] +_value >= _balances[_to]);
        uint previousBalances = _balances[_from ] + _balances[_to];
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer (_from, _to, _value);
        assert(_balances[_from] + _balances[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowances[_from][msg.sender]);
        _allowances[_from][msg.sender] -=_value;
        _transfer(_from,_to, _value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return _balances[_who];
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(_balances[_from] >= _value);
        require(_value <= _allowances[_from][msg.sender]);
        _balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function freezeToken(uint256 _amount, uint) public onlyOwner returns (bool frozen) {
        frozenAccount[msg.sender] = true;
        _energy[msg.sender] = (100 * _amount)*10**-uint(decimals);
        emit FrozenFunds (target, true);
        return true;
    }

    function unfreezeToken(address target) public onlyOwner returns (bool frozen) {
        frozenAccount[msg.sender] = false;
        emit FrozenFunds (target, false);
        return true;
    }
}
