pragma solidity ^0.4.24;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract LGmessage {
    using SafeMath for uint;
    
    struct message{
        address _sender;
        string msgcontent;
    }
    
    struct publicMessage{
        address _sender;
        string name;
        string msgcontent;
        uint reward;
    }
    
    publicMessage[] publicInbox;  //朋友圈
    mapping (address => message[]) userInbox; //用户收件箱
    mapping (address => message[]) userOutbox; //用户发件箱
    mapping (address => string) public userName;
    
    function setName(string _name)public{
        userName[msg.sender] = _name;
    }
    
    //发送信息
    function sendMsg(address to, string _message,uint issave)public{
        message memory newMessage = message({
                    _sender: msg.sender,
                    msgcontent: _message
                });
            userInbox[to].push(newMessage);
        if(issave == 1){
            message memory _newMessage = message({
                    _sender: to,
                    msgcontent: _message
                });
            userOutbox[msg.sender].push(_newMessage);
        }
        IERC20(LG).transferFrom(msg.sender,address(this), fee);
        if(isGetLG ==1 ){
             uint GXvalue = fee.mul(getLGratio).div(100);
            ILGVgongxian(ILGVgongxianAddr).addGongxianzhi(msg.sender,GXvalue);
        }
    }
    
    //发送朋友圈
    function sendPublicMsg(string _message,uint issave)public{
        publicMessage memory _publicMessage = publicMessage({
                    _sender: msg.sender,
                    name: userName[msg.sender],
                    msgcontent: _message,
                    reward: 0
                });
            publicInbox.push(_publicMessage);
        if(issave == 1){
            message memory _newMessage = message({
                    _sender: address(this),
                    msgcontent: _message
                });
            userOutbox[msg.sender].push(_newMessage);
        }
        IERC20(LG).transferFrom(msg.sender,address(this), fee);
        if(isGetLG ==1 ){
             uint GXvalue = fee.mul(getLGratio).div(100);
            ILGVgongxian(ILGVgongxianAddr).addGongxianzhi(msg.sender,GXvalue);
        }
    }
    
    //获取收件箱
    function InboxLength()public view returns(uint){
        return userInbox[msg.sender].length;
    }
    function Inbox(uint _ID)public view returns(address,string){
        message[] storage _message = userInbox[msg.sender];
        return (_message[_ID]._sender,_message[_ID].msgcontent);
    }
    
    //删除信息
    function delmessage(uint _ID)public  {
        delete userInbox[msg.sender][_ID];
    }
    
    //获取发件箱
    function OutboxLength()public view returns(uint){
        return userOutbox[msg.sender].length;
    }
    function Outbox(uint _ID)public view returns(address,string){
        message[] storage _message = userOutbox[msg.sender];
        return (_message[_ID]._sender,_message[_ID].msgcontent);
    }
    
    //获取朋友圈
    function PublicboxLength()public view returns(uint){
        return publicInbox.length;
    }
    function Publicbox(uint _ID)public view returns(address,string,string,uint){
        return (publicInbox[_ID]._sender,publicInbox[_ID].name,publicInbox[_ID].msgcontent,publicInbox[_ID].reward);
    }
    
    //打赏
    function Reward(uint _ID, uint value)public{
        publicInbox[_ID].reward = publicInbox[_ID].reward.add(value);
        IERC20(LG).transferFrom(msg.sender,address(this), value.mul(rewardFeeRatio).div(100));
        IERC20(LG).transferFrom(msg.sender,publicInbox[_ID]._sender, value.mul(100-rewardFeeRatio).div(100));
    }
    
    /////////////////////////////////////////////////////////////////////
    address public owner;
    address public LG  ; //LG通证地址
    uint public fee = 5e18;  //发信息费用
    uint public rewardFeeRatio = 30;  //打赏链改网提成，百分比
    
    address public ILGVgongxianAddr; //V贡献值记录系统地址
    uint public isGetLG; //是否可以挖矿LG,1为可以，0为不可以，默认1
    uint public getLGratio = 60 ; //挖矿LG比率，默认为60%，

    constructor(address LGadr, address _ILGVgongxianAddr) public {
        owner = msg.sender;
        LG = LGadr;
        ILGVgongxianAddr = _ILGVgongxianAddr;
    }
    modifier ownerOnly() {
        require(msg.sender == owner);
        _; 
    }
    
    function transferOwer(address newOwner)public ownerOnly{
        owner = newOwner;
    }
    
    function iLG(address adr)public ownerOnly{
        LG= adr;
    }
    //发信息费用 默认：5e18
    function ifee(uint _fee)public ownerOnly{
        fee= _fee;
    }
    //打赏链改网提成，百分比。 30 = 30%
    function irewardFeeRatio(uint _rewardFeeRatio)public ownerOnly{
        rewardFeeRatio = _rewardFeeRatio;
    }
    //平台提取手续费
    function clamLG()public ownerOnly{
        IERC20(LG).transfer(
            msg.sender,
            IERC20(LG).balanceOf(address(this))
            );
    }
    
    //设置生态挖矿系统地址
    function setILGgongxianAddr(address _ILGVgongxianAddr) public ownerOnly{
        ILGVgongxianAddr = _ILGVgongxianAddr;
    }

    //设置是否可以挖矿LG,1为可以，0为不可以，默认1
    function setisGetLG(uint _isGetLG) public ownerOnly{
        isGetLG = _isGetLG;
    }

    //设置挖矿LG比率，默认为 60 = 60%，
    function setgetLGratio(uint _getLGratio) public ownerOnly{
        getLGratio = _getLGratio;
    }
    /////////////////////////////////////////////////////////////////////

}

//合约接口
interface IERC20{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}

//生态挖矿系统地址
interface ILGVgongxian{
    function addGongxianzhi(address _user, uint _value)external;
}