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
    drawKeyboard();
    return;
  }

  drawTrialHeader();
  drawNextButton();
  drawKeyboard();
}

// Press-and-drag keyboard. All geometry is relative to the calibrated inch.
function outerRadius() { return sizeOfInputArea * .48; }
function innerRadius() { return sizeOfInputArea * .22; }

function letterAt(x, y) {
  const dx = x - width / 2, dy = y - height / 2, s = sizeOfInputArea;
  if (abs(dx) >= s / 2 || abs(dy) >= s / 2 || sqrt(dx * dx + dy * dy) < innerRadius()) return -1;
  const step = TWO_PI / 26;
  const angle = (atan2(dy, dx) + HALF_PI + step / 2 + TWO_PI) % TWO_PI;
  return Math.floor(angle / step) % 26;
}

function drawKeyboard() {
  const cx = width / 2, cy = height / 2, s = sizeOfInputArea;
  push();
  noStroke();
  fill(32, 36, 43);
  rect(cx - s / 2, cy - s / 2, s, s);
  textAlign(CENTER, CENTER);
  if (!selectingLetter) {
    fill(65, 75, 89);
    ellipse(cx, cy, s * .32, s * .32);
    fill(255);
    textSize(s * .09);
    text('Hold', cx, cy - s * .045);
    text('here', cx, cy + s * .045);
    fill(52, 93, 151);
    rect(cx - s * .48, cy + s * .30, s * .47, s * .18, 4);
    fill(149, 63, 70);
    rect(cx + s * .01, cy + s * .30, s * .47, s * .18, 4);
    fill(255);
    textSize(s * .088);
    text('SPACE', cx - s * .245, cy + s * .39);
    text('DELETE', cx + s * .245, cy + s * .39);
  } else {
    const step = TWO_PI / 26, ro = outerRadius(), ri = innerRadius();
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
      textSize(s * .074);
      const labelR = s * .39;
      text(alphabet.charAt(i), cx + labelR * cos(angle), cy + labelR * sin(angle));
    }
    fill(65, 75, 89);
    ellipse(cx, cy, ri * 2, ri * 2);
    fill(255);
    if (selectedKey >= 0) {
      textSize(s * .24);
      text(alphabet.charAt(selectedKey), cx, cy);
    } else {
      textSize(s * .075);
      text('Drag', cx, cy - s * .04);
      text('to select', cx, cy + s * .04);
    }
  }
  pop();
}

function pointerPressed() {
  if (finishTime != 0) return;
  if (startTime == 0) {
    if (dist(pointerX, pointerY, width / 2, height / 2) > sizeOfInputArea * .16) return;
    nextTrial();
    selectingLetter = true;
    selectedKey = -1;
    return;
  }
  if (inNextButton()) {
    selectingLetter = false;
    selectedKey = -1;
    nextTrial();
    return;
  }
  const cx = width / 2, cy = height / 2, s = sizeOfInputArea;
  if (didTouch(cx - s * .48, cy + s * .30, s * .47, s * .18)) {
    currentTyped += ' ';
  } else if (didTouch(cx + s * .01, cy + s * .30, s * .47, s * .18)) {
    if (currentTyped.length > 0) currentTyped = currentTyped.substring(0, currentTyped.length - 1);
  } else if (dist(pointerX, pointerY, cx, cy) <= s * .16) {
    selectingLetter = true;
    selectedKey = -1;
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
