// Prototype 4: QWERTY tap and deliberate swipe input.
const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
const dwellMillis = 90;
let swiping = false;
let swipeText = '';
let hoverLetter = '';
let hoverSince = 0;
let hoverRecorded = false;

function setup() {
  bakeoffSetup();
}

function draw() {
  textAlign(LEFT, BASELINE);
  background(255); //clear background

  //check to see if the user finished. You can't change the score computation.
  if (finishTime != 0) {
    drawResults();
    return;
  }

  drawWatch(); //draw watch background
  fill(100);
  rect(inputX(), inputY(), sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"

  if (startTime == 0) {
    drawStartMessage('Tap to start'); //display this messsage until the user taps!
    return;
  }

  drawTrialHeader();
  drawNextButton();
  drawKeyboard();
}

// All keyboard geometry is relative to the calibrated one-inch square.
function leftEdge() { return inputX(); }
function topEdge() { return inputY(); }
function keyWidth() { return sizeOfInputArea / 10; }
function rowHeight() { return sizeOfInputArea * 0.23; }
function rowLeft(r) { return width / 2 - rows[r].length * keyWidth() / 2; }
function rowTop(r) { return topEdge() + sizeOfInputArea * 0.09 + r * rowHeight(); }

function letterAt(x, y) {
  for (let r = 0; r < rows.length; r++) {
    const dx = x - rowLeft(r), dy = y - rowTop(r);
    if (dx >= 0 && dx < rows[r].length * keyWidth() && dy >= 0 && dy < rowHeight()) {
      const i = Math.floor(dx / keyWidth());
      return rows[r].substring(i, i + 1);
    }
  }
  return '';
}

function drawKeyboard() {
  if (swiping) updateSwipe();
  const s = sizeOfInputArea, x = leftEdge(), y = topEdge();
  push();
  noStroke();
  fill(32, 36, 43); rect(x, y, s, s);
  textAlign(CENTER, CENTER);
  fill(255); textSize(s * 0.065);
  let preview = swipeText;
  if (preview.length > 14) preview = preview.substring(preview.length - 14);
  text(preview, x + s / 2, y + s * 0.045);
  for (let r = 0; r < rows.length; r++) {
    for (let i = 0; i < rows[r].length; i++) {
      const c = rows[r].substring(i, i + 1);
      const kx = rowLeft(r) + i * keyWidth(), ky = rowTop(r);
      fill(swiping && c == hoverLetter ? color(37, 99, 235) : color(65, 75, 89));
      rect(kx + .5, ky + .5, keyWidth() - 1, rowHeight() - 1, 2);
      fill(255); textSize(s * 0.075);
      text(c, kx + keyWidth() / 2, ky + rowHeight() / 2);
    }
  }
  fill(52, 93, 151); rect(x + 1, y + s * .79, s * .70 - 2, s * .21 - 1, 3);
  fill(149, 63, 70); rect(x + s * .70 + 1, y + s * .79, s * .30 - 2, s * .21 - 1, 3);
  fill(255); textSize(s * 0.085);
  text('SPACE', x + s * .35, y + s * .895);
  text('DEL', x + s * .85, y + s * .895);
  pop();
}

function resetSwipe() {
  swiping = false; swipeText = ''; hoverLetter = ''; hoverRecorded = false;
}

function recordLetter(c) {
  if (c.length > 0) swipeText += c;
  hoverRecorded = true;
}

// Pausing briefly on an intermediate key selects it; passing over keys does not.
function updateSwipe() {
  const c = letterAt(pointerX, pointerY);
  if (c != hoverLetter) {
    hoverLetter = c; hoverSince = millis(); hoverRecorded = false;
  }
  if (c.length > 0 && !hoverRecorded && millis() - hoverSince >= dwellMillis) recordLetter(c);
}

function pointerPressed() {
  if (finishTime != 0) return;
  if (startTime == 0) {
    nextTrial(); //start the trials!
    return;
  }
  resetSwipe();
  if (inNextButton()) { nextTrial(); return; }
  const x = leftEdge(), y = topEdge(), s = sizeOfInputArea;
  if (didTouch(x, y + s * .79, s * .70, s * .21)) { currentTyped += ' '; return; }
  if (didTouch(x + s * .70, y + s * .79, s * .30, s * .21)) {
    if (currentTyped.length > 0) currentTyped = currentTyped.substring(0, currentTyped.length - 1);
    return;
  }
  const c = letterAt(pointerX, pointerY);
  if (c.length > 0) {
    swiping = true; hoverLetter = c; hoverSince = millis(); recordLetter(c);
  }
}

function pointerDragged() { if (swiping) updateSwipe(); }

function pointerReleased() {
  if (!swiping) return;
  updateSwipe();
  if (hoverLetter.length > 0 && finishTime == 0) {
    if (!hoverRecorded) recordLetter(hoverLetter);
    currentTyped += swipeText;
  }
  resetSwipe();
}
