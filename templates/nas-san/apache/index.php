<?php
// Handle form submission
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $nom = $_POST['nom'] ?? '';
    $mail = $_POST['mail'] ?? '';
    $message = $_POST['message'] ?? '';

    $to = $mail;
    $subject = "Message de $nom";
    $body = $message;
    $headers = "From: $nom@apache.vagrant-dummy-ops.lab\r\n";

    if (mail($to, $subject, $body, $headers)) {
        echo "Mail envoyé !";
    } else {
        echo "Échec de l'envoi.";
    }

    // Stop execution so HTML form is not printed
    exit;
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <title>DUMMY-APACHE</title>
  <meta charset="utf-8" />
  <link rel="icon" href="favicon.ico"/>
  <meta name="author" content="shijuro"/>
  <meta name="keywords" content="html5 css3 js"/>
  <meta name="description" content="dummy web page"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <link href="https://fonts.googleapis.com/css?family=Barlow+Semi+Condensed&display=swap" rel="stylesheet">
  <link rel="stylesheet" type="text/css" href="css/styles.css"/>
</head>
<body>
<header>
<nav>
	<ul>
		<li><a href="#">HOME</a></li>
    <li><a href="#">ABOUT</a></li>
	</ul>
</nav>
</header>

<div class="hero-box">
  <div class="form">
    <form method="POST" action="" enctype="application/x-www-form-urlencoded">
      <legend>MAILING LIST</legend>

      <label for="nom">YOUR USERNAME</label><br>
      <input type="text" size=28 name="nom" id="nom" pattern="[a-zA-Z0-9]{3,}" required><br>

      <label for="mail">WHO YOU MAIL</label><br>
      <input type="email" size=28 name="mail" id="mail" required><br>

      <label for="message">MESSAGE YOU MAIL</label><br>
      <textarea name="message" id="message" rows="5" cols="30" required></textarea><br>

      <input type="submit" name="submit" value="VALIDER">
    </form>
  </div>
</div>

<footer></footer>
<script src="js/bootstrap.bundle.min.js" type="text/javascript"></script>
</body>
</html>
