const letterGroups = ['abcde', 'fghij', 'klmno', 'pqrst', 'uvwxyz'];
let activeGroup = -1;

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

// Two-column keyboard: six selection cells plus a full-width bottom button.
function keyLabel(index) {
  if (index == 6) return activeGroup == -1 ? 'delete' : 'back';
  if (activeGroup == -1) return index < 5 ? letterGroups[index] : 'space';
  const letters = letterGroups[activeGroup];
  return index < letters.length ? letters.substring(index, index + 1) : '';
}

function drawKeyboard() {
  const x = inputX();
  const y = inputY();
  const w = sizeOfInputArea / 2;
  const h = sizeOfInputArea / 4;
  push();
  noStroke();
  textAlign(CENTER, CENTER);
  for (let i = 0; i < 7; i++) {
    const label = keyLabel(i);
    const bx = x + (i % 2) * w, by = y + Math.floor(i / 2) * h;
    const bw = i == 6 ? sizeOfInputArea : w;
    fill(label.length == 0 ? color(45) : i == 6 ? color(145, 55, 60) : label == 'space' ? color(45, 105, 80) : color(45, 90, 150));
    rect(bx + 1, by + 1, bw - 2, h - 2, 3);
    fill(255);
    textSize(label.length > 1 ? sizeOfInputArea * .105 : sizeOfInputArea * .17);
    text(label, bx + bw / 2, by + h / 2);
  }
  pop();
}

function pointerPressed() {
  if (finishTime != 0) return;
  if (startTime == 0) {
    nextTrial(); //start the trials!
    return;
  }
  if (inNextButton()) {
    activeGroup = -1;
    nextTrial();
    return;
  }
  const x = inputX(), y = inputY();
  if (!didTouch(x, y, sizeOfInputArea, sizeOfInputArea)) return;
  const row = Math.floor((pointerY - y) / (sizeOfInputArea / 4));
  const col = Math.floor((pointerX - x) / (sizeOfInputArea / 2));
  const index = row == 3 ? 6 : row * 2 + col;
  if (index == 6) {
    if (activeGroup != -1) activeGroup = -1;
    else if (currentTyped.length > 0) currentTyped = currentTyped.substring(0, currentTyped.length - 1);
  } else if (activeGroup == -1) {
    if (index == 5) currentTyped += ' ';
    else activeGroup = index;
  } else {
    const letters = letterGroups[activeGroup];
    if (index < letters.length) {
      currentTyped += letters.charAt(index);
      activeGroup = -1;
    }
  }
}
