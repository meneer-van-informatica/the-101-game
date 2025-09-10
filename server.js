const express = require('express');
const app = express();
const port = 3000;

// Stel een eenvoudige route in voor de Engelse landingspagina
app.get('/', (req, res) => {
  if (req.hostname === 'the101game.io') {
    res.sendFile(__dirname + '/public/english.html');
  } else if (req.hostname === 'the101game.nl') {
    res.sendFile(__dirname + '/public/dutch.html');
  } else {
    res.status(404).send('Pagina niet gevonden');
  }
});

// Server starten
app.listen(port, () => {
  console.log(`Server draait op http://localhost:${port}`);
});
