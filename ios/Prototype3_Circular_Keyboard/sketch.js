const alphabet = 'abcdefghijklmnopqrstuvwxyz';
let selectedKey = -1;
let selectingLetter = false;

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

// Circular keyboard; all dimensions are relative to the calibrated inch.
function outerRadius() { return sizeOfInputArea * .48; }
function innerRadius() { return sizeOfInputArea * .30; }

function letterAt(x, y) {
  const dx = x - width / 2, dy = y - height / 2;
  const r = sqrt(dx * dx + dy * dy);
  if (r < innerRadius() || r > outerRadius()) return -1;
  const step = TWO_PI / 26;
  const angle = (atan2(dy, dx) + HALF_PI + step / 2 + TWO_PI) % TWO_PI;
  return Math.floor(angle / step) % 26;
}

function drawKeyboard() {
  const cx = width / 2, cy = height / 2, s = sizeOfInputArea;
  const step = TWO_PI / 26, ro = outerRadius(), ri = innerRadius();
  push();
  noStroke();
  fill(32, 36, 43);
  rect(cx - s / 2, cy - s / 2, s, s);
  textAlign(CENTER, CENTER);
  for (let i = 0; i < 26; i++) {
    const angle = -HALF_PI + i * step;
    fill(i == selectedKey ? color(37, 99, 235) : color(57, 67, 81));
    stroke(32, 36, 43);
    strokeWeight(1);
    beginShape();
    for (let j = 0; j <= 8; j++) {
      const t = angle - step / 2 + step * j / 8;
      vertex(cx + ro * cos(t), cy + ro * sin(t));
    }
    for (let j = 8; j >= 0; j--) {
      const t = angle - step / 2 + step * j / 8;
      vertex(cx + ri * cos(t), cy + ri * sin(t));
    }
    endShape(CLOSE);
    noStroke();
    fill(255);
    textSize(s * .073);
    text(alphabet.charAt(i), cx + (ro + ri) / 2 * cos(angle), cy + (ro + ri) / 2 * sin(angle));
  }
  const bw = s * .40, bh = s * .16;
  fill(52, 93, 151);
  rect(cx - bw / 2, cy - s * .18, bw, bh, 4);
  fill(149, 63, 70);
  rect(cx - bw / 2, cy + s * .02, bw, bh, 4);
  fill(255);
  textSize(s * .088);
  text('SPACE', cx, cy - s * .10);
  text('DELETE', cx, cy + s * .10);
  pop();
}

function pointerPressed() {
  if (finishTime != 0) return;
  if (startTime == 0) {
    nextTrial(); //start the trials!
    return;
  }
  if (inNextButton()) {
    selectingLetter = false;
    selectedKey = -1;
    nextTrial();
    return;
  }
  const cx = width / 2, cy = height / 2, s = sizeOfInputArea;
  if (didTouch(cx - s * .20, cy - s * .18, s * .40, s * .16)) {
    currentTyped += ' ';
  } else if (didTouch(cx - s * .20, cy + s * .02, s * .40, s * .16)) {
    if (currentTyped.length > 0) currentTyped = currentTyped.substring(0, currentTyped.length - 1);
  } else {
    selectedKey = letterAt(pointerX, pointerY);
    selectingLetter = selectedKey >= 0;
  }
}

function pointerDragged() {
  if (selectingLetter) selectedKey = letterAt(pointerX, pointerY);
}

function pointerReleased() {
  if (!selectingLetter) return;
  const k = letterAt(pointerX, pointerY);
  if (k >= 0 && finishTime == 0) currentTyped += alphabet.charAt(k);
  selectedKey = -1;
  selectingLetter = false;
}
