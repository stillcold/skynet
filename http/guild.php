<?php

require "config.php";

error_reporting(0); //抑制所有错误信息
@header("content-Type: text/html; charset=utf-8"); //语言强制
ob_start();

function valid_email($str) 
{
  return ( ! preg_match("/^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$/ix", $str)) ? FALSE : TRUE;
}

//检测PHP设置参数
function show($varName)
{
  switch($result = get_cfg_var($varName))
  {
    case 0:
      return '<font color="red">×</font>';
    break;
    
    case 1:
      return '<font color="green">√</font>';
    break;
    
    default:
      return $result;
    break;
  }
}


if ($_GET['act'] == "phpinfo") 
{
  phpinfo();
  exit();
} 
elseif($_GET['act'] == "Function")
{
  $arr = get_defined_functions();
  Function php()
  {
  }
  echo "<pre>";
  Echo "这里显示系统所支持的所有函数,和自定义函数\n";
  print_r($arr);
  echo "</pre>";
  exit();
}elseif($_GET['act'] == "disable_functions")
{
  $disFuns=get_cfg_var("disable_functions");
  if(empty($disFuns))
  {
    $arr = '<font color=red>×</font>';
  }
  else
  { 
    $arr = $disFuns;
  }
  Function php()
  {
  }
  echo "<pre>";
  Echo "这里显示系统被禁用的函数\n";
  print_r($arr);
  echo "</pre>";
  exit();
}

//MySQL检测
if ($_POST['act'] == 'MySQL检测')
{
  $host = isset($_POST['host']) ? trim($_POST['host']) : '';
  $port = isset($_POST['port']) ? (int) $_POST['port'] : '';
  $login = isset($_POST['login']) ? trim($_POST['login']) : '';
  $password = isset($_POST['password']) ? trim($_POST['password']) : '';
  $host = preg_match('~[^a-z0-9\-\.]+~i', $host) ? '' : $host;
  $port = intval($port) ? intval($port) : '';
  $login = preg_match('~[^a-z0-9\_\-]+~i', $login) ? '' : htmlspecialchars($login);
  $password = is_string($password) ? htmlspecialchars($password) : '';
}
elseif ($_POST['act'] == '函数检测')
{
  $funRe = "函数".$_POST['funName']."支持状况检测结果：".isfun1($_POST['funName']);
}
elseif ($_POST['act'] == '说给你听')
{
  $t= date('Ymd_H_i_s',time());
  if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ip = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
} else {
    $ip = $_SERVER['REMOTE_ADDR'];
}
  saveMessage($_POST['message'], $t, $ip);
  $funRe = "留言收到！";
} 
elseif ($_POST['act'] == '邮件检测')
{
  $mailRe = "邮件发送检测结果：发送";
  if($_SERVER['SERVER_PORT']==80){$mailContent = "http://".$_SERVER['SERVER_NAME'].($_SERVER['PHP_SELF'] ? $_SERVER['PHP_SELF'] : $_SERVER['SCRIPT_NAME']);}
  else{$mailContent = "http://".$_SERVER['SERVER_NAME'].":".$_SERVER['SERVER_PORT'].($_SERVER['PHP_SELF'] ? $_SERVER['PHP_SELF'] : $_SERVER['SCRIPT_NAME']);}
  $mailRe .= (false !== @mail($_POST["mailAdd"], $mailContent, "This is a test mail!\n\nhttp://lnmp.org")) ? "完成":"失败";
} 
  
// 检测函数支持
function isfun($funName = '')
{
    if (!$funName || trim($funName) == '' || preg_match('~[^a-z0-9\_]+~i', $funName, $tmp)) return '错误';
  return (false !== function_exists($funName)) ? '<font color="green">√</font>' : '<font color="red">×</font>';
}
function isfun1($funName = '')
{
    if (!$funName || trim($funName) == '' || preg_match('~[^a-z0-9\_]+~i', $funName, $tmp)) return '错误';
  return (false !== function_exists($funName)) ? '√' : '×';
}

function saveMessage($message = '', $fileName = '', $ip = '')
{
  
  file_put_contents("./../messages/".$fileName.".txt", $message."\n", FILE_APPEND);
  file_put_contents("./../messages/".$fileName.".txt", $ip."\n", FILE_APPEND);
}

?>

<!DOCTYPE html >
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>欢迎光临</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8;initial-scale=1.0, maximum-scale=1.0, user-scalable=0;" name="viewport" />

<style type="text/css">
<!--
* {font-family: Tahoma, "Microsoft Yahei", Arial; }
h1 {font-size: 30px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h2 {font-size: 20px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h3 {font-size: 10px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
body{ margin: 0 auto; padding: 0; background-color:#FFFFFF;font-size:30px;font-family:Tahoma, Arial}
table{clear:both;padding: 0; margin: 0 0 10px;border-collapse:collapse; border-spacing: 0;height:80%;width:80%;}
th{padding: 3px 6px; font-size: 30px;font-weight:bold;background:#3066a6;color:#FFFFFF;border:1px solid #3066a6; text-align:left;}
input.btn{font-weight: bold; height: 60px; width:200px;line-height: 20px; padding: 0 6px; color:#666666; background: #f2f2f2; border:1px solid #999;font-size:30px}
.footer{ bottom: 0px;  
  left: 0px;  
  color: #666;  
  width: 100%;  
  clear: both;//清除浮动  
  line-height: 90px;  
  background-color: #ebebed; position: fixed;}
-->
</style>

</head>
<body>
    <div id="header" align="center">
    </div>

<iframe frameborder="0" scrolling="no" src="guild_title_release.html" width="100%" height="500px"></iframe>
<div id="footer">


</div>

<div id="page" align="center">

<br>
<br>
<form action="<?php echo $_SERVER[PHP_SELF]."#bottom";?>" method="post">
<!--发送数据-->
<table width="100%" cellpadding="3" cellspacing="0" align="center">
  <tr><th colspan="3">有话要对管理说嘛?但这里是匿名哦,我们并不知道你是谁啦</th></tr>
  <tr>
    <td width="15%"></td>
    <td width="50%">
      <input type="text" name="message" size="50" maxlength="600" style="height:50px;" />
    </td>
    <td width="25%">
      <input class="btn" type="submit" name="act" align="right" value="说给你听" />
    </td>
  </tr>
  <?php
  if ($_POST['act'] == '说给你听') {
    echo "<script>alert('$funRe')</script>";
  }
  ?>
</table>
</form>
</div>

<br>

<marquee width=100% height=200 bgcolor=white direction=up scrollamount=3 style=""padding:20px;>
<ul>
  <li>谁说生活没有彩排，游戏就是对生活最好的彩排，体验游戏，感悟生活</li>
  <li>帮会是倾诉故事和分享快乐的最佳集散中心，你若真心，必然收获真心</li>
  <li>我们更希望更多成员更多的参与帮会活动和聊天，例如寇岛、联赛、帮花</li>
  <li>我们目前最重视周二和周四的帮会联赛，其次是周日寇岛和周五帮花</li>
  <li>联赛开始时间为每个周二的8点和每个周四的8点，其中周二有两场</li>
  <li>寇岛开启时间为周日晚上9点，帮花为周五9点</li>
</ul>
</marquee>

<br>
<br>
<br>

<div class="footer">

<div align="center">这里是倩女幽魂手游血染白霜帮会的主页，并非游戏官方网站！</div>
<div id="jump" align="center">
<a href="http://qnm.163.com/index.html">游戏官网</a> <a href="how_to_play.php">玩法攻略</a> <a href="member_info_debug.php">成员介绍</a> <a href="about_guild.php">关于本站</a>
<h3>版权所有.乍暖还寒</h3>
</div>
</div>


</body>
</html>