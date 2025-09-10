<?php
$servername = "localhost";
$username = "admin";
$password = "admin_password"; // of je wachtwoord voor de admin gebruiker
$dbname = "the101game_db";

// Maak verbinding
$conn = new mysqli($servername, $username, $password, $dbname);

// Check de verbinding
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";
?>
