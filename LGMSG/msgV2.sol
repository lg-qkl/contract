pragma solidity ^0.4.26;

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
    
    
    mapping (address => address[]) blackBox; //黑名单
    mapping (address => address[]) Outbox; //发送给了哪些人
    mapping (address => message[]) userInbox; //用户收件箱
    publicMessage[] publicInbox;  //朋友圈
    mapping (address => string) public userName;

    function setName(string _name)public{
        userName[msg.sender] = _name;
    }
    
    //发送信息
    function sendMsg(address to, string _message)public{
        message memory newMessage = message({
                    _sender: msg.sender,
                    msgcontent: _message
                });
        for(uint i=0; i<Outbox[msg.sender].length;i++){
            if(Outbox[msg.sender][i] == to){
                uint8 a = 1;
            }
        }
        if(a!=1){
            Outbox[msg.sender].push(to);
        }
        userInbox[to].push(newMessage);
    }
    
    //发送朋友圈
    function sendPublicMsg(string _message)public{
        publicMessage memory _publicMessage = publicMessage({
                    _sender: msg.sender,
                    name: userName[msg.sender],
                    msgcontent: _message,
                    reward: 0
                });
            publicInbox.push(_publicMessage);
        IERC20(LG).transferFrom(msg.sender,address(this), fee);
    }
    
    //获取收件箱
    function InboxLength()public view returns(uint){
        return userInbox[msg.sender].length;
    }
    function Inbox()public view returns(string[]){
        string[] msg;
        for(uint8 i =0;i<userInbox[msg.sender].length;i++){
            msg.push(userInbox[i].msgcontent);
        }
        return msg;
    }
    
    
    //获取已发送信息
    function getOutbox()public view returns(address[]) {
        return Outbox[msg.sender];
    }
    function OutWho(address who)public view returns(uint[]){
        uint len = userInbox[who].length;
        uint[] msgid;
        message[] storage _message = userInbox[who];
        for(uint i=0; i<len; i++){
            if(_message[i]._sender == msg.sender){
                msgid.push(i);
            }
        }
        return msgid;
    }
    function OutMsg(address who, uint _ID)public view returns(address,string){
        message[] storage _message = userInbox[who];
        if(_message[_ID]._sender == msg.sender){
            return (_message[_ID]._sender,_message[_ID].msgcontent);
        }
    }
    
    
    //黑名单
    function addblackBox(address _who)public  {
        blackBox[msg.sender].push(_who);
    }
    function getblackBox()public view returns(address[]) {
        return blackBox[msg.sender];
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
        IERC20(LG).transferFrom(msg.sender,address(this), value);
    }
    
    //提赏金  +平台提成数额添加
    
    
    /////////////////////////////////////////////////////////////////////
    address public owner;
    address public LG  ; //LG通证地址
    uint public fee = 5e18;  //发信息费用
    uint public rewardFeeRatio = 30;  //打赏链改网提成，百分比

    constructor(address LGadr) public {
        owner = msg.sender;
        LG = LGadr;
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
    /////////////////////////////////////////////////////////////////////

}

//合约接口
interface IERC20{
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function transferFrom(address from, address to, uint256 value)external returns (bool);
}