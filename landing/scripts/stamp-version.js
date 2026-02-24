const fs = require('fs');
const { version } = require('../package.json');

const file = 'build/index.html';
let html = fs.readFileSync(file, 'utf8');
html = html.replace(/css\/style\.css/g, `css/style.css?v=${version}`);
html = html.replace(/js\/main\.js/g, `js/main.js?v=${version}`);
fs.writeFileSync(file, html);
