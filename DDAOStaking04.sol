/* ============================================= DEFI HUNTERS DAO ================================================================
                                           https://defihuntersdao.club/                                                                                                             
------------------------------------------------ 12 november 2022 ----------------------------------------------------------------
#######    #######    ######       ####                  ######   #########  ######    #####  #### ########  ###   #####   #######  
 ##   ###   ##   ###     ###      ### ###               ### ###   #  ##  ##     ###      #    ###      #      ###    ##  ###   ###  
 ##    ##   ##    ##    ## ##    ##     ##             ##     #   #  ##  ##    ## ##     #  ###        #      ####   ##  ##     ##  
 ##     ##  ##     ##  ##  ##   ##       #              ###          ##       ##  ##     ####          #      ## ##  ##  #          
 ##     ##  ##     ##  #######  ##       ##               #####      ##       #######    ######        #      ##  ## ##  #   ###### 
 ##     #   ##     #  ##    ##   ##     ##             ##     ##     ##      ##    ##    #   ###       #      ##  #####  #      ##  
 ##   ###   ##   ###  ##     ##  ###   ###             ##    ###     ##      ##     ##   #    ##       #      ##   ####  ###    ##  
########   ########  ####   ####   #####               ########    #######  ####   #########   ### ########  #####  ###    #######  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITxs
{
    function TxsAdd(address addr,uint256 amount,string memory name,uint256 id1,uint256 id2)external returns(uint256);
    function TxsCount(address addr)external returns(uint256);
    function EventAdd(uint256 txcount,address addr,uint256 user_id,uint256 garden,uint256 level,uint256 amount,string memory name)external returns(uint256);

}
interface IToken
{
    function approve(address spender,uint256 amount)external;
    function allowance(address owner,address spender)external view returns(uint256);
    function balanceOf(address addr)external view returns(uint256);
    function decimals() external view  returns (uint8);
    function name() external view  returns (string memory);
    function symbol() external view  returns (string memory);
    function totalSupply() external view  returns (uint256);
}

contract DDAOStaking is AccessControl
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

	address public TxAddr = 0xB7CC7b951DAdADacEa3A8E227F25cd2a45c64284;
	address[] public Users;
	address public TokenAddress;
	uint256 public StakeTime;
	event StakeLog(string name,address addr,uint256 time,uint256 amount, uint256 frozen,uint256 unlock);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	Admins.push(_msgSender());
	AdminAdd(0x208b02f98d36983982eA9c0cdC6B3208e0f198A3);
	if(_msgSender() != 0x80C01D52e55e5e870C43652891fb44D1810b28A2)
	AdminAdd(0x80C01D52e55e5e870C43652891fb44D1810b28A2);

        StakeTime = 5 * 86400;
//        StakeTime = 5 *3600;

	    if(block.chainid == 137)
	    {
		// DDAO
		TokenAddress = 0x90F3edc7D5298918F7BB51694134b07356F7d0C7;
		// AppDDAO Learn
		//TokenAddress = 0x19Ca9521Ec3F01a03476323dd54740C1239eF5e5;
	    }

	    if(block.chainid == 80001)
	    {
	    }
	    if(block.chainid == 3)
	    {
	    }

	}

	// Start: Admin functions
	event adminModify(string txt, address addr);
	address[] Admins;
	modifier onlyAdmin() 
	{
		require(IsAdmin(_msgSender()), "Access for Admin's only");
		_;
	}
	function IsAdmin(address account) public virtual view returns (bool)
	{
	    	return hasRole(DEFAULT_ADMIN_ROLE, account);
	}
	function AdminAdd(address account) public virtual onlyAdmin
	{
		require(!IsAdmin(account),'Account already ADMIN');
		grantRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin added',account);
		Admins.push(account);
	}
	function AdminDel(address account) public virtual onlyAdmin
	{
		require(IsAdmin(account),'Account not ADMIN');
		require(_msgSender()!=account,'You can`t remove yourself');
		revokeRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin deleted',account);
	}
    function AdminList()public view returns(address[] memory)
    {
	return Admins;
    }
        /**                                                                                                                                                                                 
        Tokens have already been sold to customers and they have received aDDAO.                                                                                                            
        We answer with our name.                                                                                                                                                            
        In the last change, we added token addresses directly to the contract so that                                                                                                       
        it would not be visible that these are not proxy contracts. The withdrawal of                                                                                                       
        tokens is needed in case we are somehow broken, despite all the tests and audits,                                                                                                   
        so that we can withdraw and redo the contract                                                                                                                                       
        **/             
    function AdminGetCoin(uint256 amount) public onlyAdmin
    {
        payable(_msgSender()).transfer(amount);
    }

    function AdminGetToken(address tokenAddress, uint256 amount) public onlyAdmin
    {
        IERC20 ierc20Token = IERC20(tokenAddress);
        ierc20Token.safeTransfer(_msgSender(), amount);
    }
    function TxsAddrChange(address addr)public onlyAdmin
    {
	require(TxAddr != addr,"This address already set");
	TxAddr = addr;
    }
    // End: Admin functions

    function AddCoin()public payable returns(bool)
    {
	return true;
    }
    function name()public pure returns(string memory)
    {
	return "DDAO Staking";
    }
    function symbol() public pure returns(string memory)
    {
	return "stDDAO";
    }
    function decimals()public view returns(uint8)
    {
	return IToken(TokenAddress).decimals();
    }
    function StakeAllowance(address addr)public view returns(uint256)
    {
	return IToken(TokenAddress).allowance(addr,address(this));
    }
    struct sstake
    {
	bool enable;
	uint256 amount;
	uint256 unlock;
	uint256 frozen;
	uint256 time;
    }
    /** Changing the staking period after which all tokens will be available for the allocation pool **/
    function StakeTimeChange(uint256 time)public onlyAdmin
    {
	StakeTime = time;
    }
    uint256 public StakeCount = 0;
    mapping (address => sstake) public StakeWal; 
	// owner ddao and his friend
        /**
        Any address can be staking. It is necessary that there are tokens on the balance.
        For example, the user has a hot, cold wallet, Ledger, Trezor, etc.
        To simplify the work with tokens for participation in sales or other events from https://defihuntersdao.club/
        you can perform actions from one address that are not related to withdrawals.
        !!! Important: If the sender of this transaction stakes for an address that does not belong to him, access to the tokens is lost forever.
        **/
    function Stake(address addr,uint256 amount)public
    {
	uint256 t;
	if(StakeWal[addr].enable != true)
	{
	    StakeWal[addr].time = block.timestamp;
	    StakeWal[addr].enable = true;
	    StakeWal[addr].amount = 0;
	    StakeWal[addr].frozen = 0;
	    StakeWal[addr].unlock = 0;

	    StakeCount = StakeCount.add(1);
	    Users.push(addr);
	}
	t = StakeUnlockCalc(addr,0);
	StakeWal[addr].amount = StakeWal[addr].amount.add(amount);
	StakeWal[addr].unlock = StakeWal[addr].unlock.add(t);
	StakeWal[addr].frozen = StakeWal[addr].amount.sub(StakeWal[addr].unlock);
	StakeWal[addr].time = block.timestamp;

	IERC20(TokenAddress).safeTransferFrom(_msgSender(),address(this), amount);
	emit StakeLog("stake",addr,StakeWal[addr].time,StakeWal[addr].amount,StakeWal[addr].frozen,StakeWal[addr].unlock);
    
        uint256 tx_id = ITxs(TxAddr).TxsAdd(addr,amount,"Stake",0,0);
        ITxs(TxAddr).EventAdd(tx_id,addr,0,1,0,amount,"Staked");

    }
    function Stake(uint256 amount)public
    {
	Stake(_msgSender(),amount);
    }
    function Unstake(uint256 amount)public
    {
	address addr = _msgSender();
	require(StakeWal[addr].amount >= amount,"Requested amount exceeds balance");
	require(BalanceCheck(addr),"Wrong balance calculation");

	StakeWal[addr].amount = StakeWal[addr].amount.sub(amount);
	StakeWal[addr].frozen = StakeWal[addr].amount;
	StakeWal[addr].unlock = 0;
	StakeWal[addr].time = block.timestamp;
	IERC20(TokenAddress).safeTransfer(_msgSender(), amount);

	if(StakeWal[addr].amount ==0)
	{
	    StakeCount = StakeCount.add(1);
	}
	emit StakeLog("unstake",addr,StakeWal[addr].time,StakeWal[addr].amount,StakeWal[addr].frozen,StakeWal[addr].unlock);
        uint256 tx_id = ITxs(TxAddr).TxsAdd(addr,amount,"Untake",0,0);
        ITxs(TxAddr).EventAdd(tx_id,addr,0,1,0,amount,"Unstaked");

    }
    /**
    It is not possible to withdraw the entire amount from staking. Can be taken in parts. But the countdown for unlocking will start from the beginning
    **/
    function UnstakeLocked()public
    {
	address addr = _msgSender();
	uint256 amount = balanceOf(addr) - StakeUnlockCalc(addr,0);
	Unstake(amount);
    }
    function UnstakeAll()public
    {
	address addr = _msgSender();
	Unstake(balanceOf(addr));
    }
    function balanceOf(address addr)public view returns(uint256 balance)
    {
	balance = StakeWal[addr].amount;
    }
    /**
    control function. Compares the amount of locked and unlocked tokens - the result should be the sum of the tokens staked.
    **/
    function BalanceCheck(address addr)public view returns(bool out)
    {
	out = false;
	if(StakeWal[addr].frozen.add(StakeWal[addr].unlock) == StakeWal[addr].amount)out = true;
    }
    // The function calculates the amount of tokens already unfrozen at the specified address.
    function StakeUnlockCalc(address addr,uint256 utime)public view returns(uint256 out)
    {
	uint256 delta;
	if(utime == 0)
	utime = block.timestamp;
	if((utime.sub(StakeWal[addr].time) >= StakeTime))
	{
	    out = StakeWal[addr].unlock + StakeWal[addr].frozen;
	}
	else
	{
	    delta = utime.sub(StakeWal[addr].time);
	    delta = delta * 10**6;
	    delta = delta.div(StakeTime);
	    out = StakeWal[addr].frozen.mul(delta).div(10**6);
	    out = out.add(StakeWal[addr].unlock);
	}
    }
    /**
    Lobster, Shark, Whale calculate
    **/
    function balanceOfLevel(address addr,uint8 level,uint256 utime) public view returns(uint256)
    {
        uint256 balance = StakeUnlockCalc(addr,utime);
	balance = balance.add(StakeWal[addr].unlock);
        uint8 level1 = 0;
        uint8 level2 = 0;
        uint8 level3 = 0;
	uint8 d = IToken(TokenAddress).decimals();
        if(balance >=  3000 * 10**d && balance < 12000 * 10**d) {level1 = 1;}
        if(balance >= 12000 * 10**d && balance < 15000 * 10**d) {level2 = 1;}
        if(balance >= 15000 * 10**d && balance < 30000 * 10**d) {level1 = 1;level2 = 1;}
        if(balance >= 30000 * 10**d && balance < 33000 * 10**d) {level3 = 1;}
        if(balance >= 33000 * 10**d && balance < 42000 * 10**d) {level1 = 1;level3 = 1;}
        if(balance >= 42000 * 10**d && balance < 45000 * 10**d) {level2 = 1;level3 = 1;}
        if(balance >= 45000 * 10**d)                             {level1 = 1;level2 = 1;level3 = 1;}

        
        if(level == 1)return level1;
        if(level == 2)return level2;
        if(level == 3)return level3;
        return 0;
    }
    function StakersCount()public view returns(uint256)                                                                                                                                 
    {                                                                                                                                                                                   
        return Users.length;                                                                                                                                                            
    }                                                                                                                                                                                   
    function StakersList()public view returns(address[] memory)                                                                                                                         
    {                                                                                                                                                                                   
        return Users;                                                                                                                                                                   
    }
    function Holders()public view returns(uint256 out)
    {
	uint256 l = StakersCount();
	uint256 i;
	for(i=0;i<l;i++)
	{
	    if(balanceOf(Users[i])>0)
	    out++;
	}
    }
    function totalSupply()public view returns(uint256)
    {
	return IToken(TokenAddress).balanceOf(address(this));
    }
}