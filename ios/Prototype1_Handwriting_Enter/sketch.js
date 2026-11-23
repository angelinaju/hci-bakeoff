// Handwriting input accepts multiple strokes; ENTER commits the letter.
let strokePoints = [];
const ink = [];
const shapeTemplates = [];
const shapeLetters = [];
let drawingLetter = false;
let outsidePad = false;

function setup() {
  bakeoffSetup();
  buildTemplates();
}

function draw() {
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
    drawStartMessage('Tap to start');
    return;
  }

  drawTrialHeader();
  drawNextButton();
  drawWritingPad();
}

function pointerPressed() {
  if (finishTime != 0) return;
  if (startTime == 0) {
    if (didTouch(inputX(), inputY(), sizeOfInputArea, sizeOfInputArea)) nextTrial();
    return;
  }

  //You are allowed to have a next button outside the 1" area
  if (inNextButton()) {
    clearInk();
    nextTrial(); //if so, advance to next trial
    return;
  }

  const x = inputX();
  const y = inputY();
  const w = sizeOfInputArea;
  const h = w * .75;

  if (didTouch(x, y + h, w / 3, w - h)) {
    if (ink.length == 0) currentTyped += ' ';
  } else if (didTouch(x + w / 3, y + h, w / 3, w - h)) {
    if (ink.length > 0) {
      currentTyped += recognizeInk();
      clearInk();
    }
  } else if (didTouch(x + 2 * w / 3, y + h, w / 3, w - h)) {
    if (ink.length > 0) clearInk();
    else if (currentTyped.length > 0)
      currentTyped = currentTyped.substring(0, currentTyped.length - 1);
  } else if (inWritingPad()) {
    strokePoints = [];
    drawingLetter = true;
    outsidePad = false;
    strokePoints.push({ x: pointerX, y: pointerY });
  }
}

function clearInk() {
  ink.length = 0;
  strokePoints = [];
  drawingLetter = false;
  outsidePad = false;
}

function inWritingPad() {
  return didTouch(inputX(), inputY(), sizeOfInputArea, sizeOfInputArea * .75);
}

function pointerDragged() {
  if (!drawingLetter) return;
  // Cancel strokes that leave the writing area instead of accepting outside input.
  if (!inWritingPad()) {
    outsidePad = true;
    return;
  }
  if (!outsidePad) strokePoints.push({ x: pointerX, y: pointerY });
}

function pointerReleased() {
  if (!drawingLetter) return;
  drawingLetter = false;
  if (!outsidePad && inWritingPad()) {
    strokePoints.push({ x: pointerX, y: pointerY });
    ink.push(strokePoints);
  }
  strokePoints = [];
}

function drawInkStroke(points) {
  if (points.length > 0) point(points[0].x, points[0].y);
  for (let i = 1; i < points.length; i++)
    line(points[i - 1].x, points[i - 1].y, points[i].x, points[i].y);
}

function drawWritingPad() {
  const x = inputX(), y = inputY(), w = sizeOfInputArea, h = w * .75;
  push();
  noStroke(); fill(35); rect(x, y, w, h);
  if (!drawingLetter && ink.length == 0) {
    fill(180); textAlign(CENTER, CENTER); textSize(w * .10);
    text('draw a letter', x + w / 2, y + h / 2);
  }
  stroke(100, 190, 255); strokeWeight(max(2, w * .02)); strokeCap(ROUND); strokeJoin(ROUND);
  for (const pts of ink) drawInkStroke(pts);
  if (drawingLetter && !outsidePad) drawInkStroke(strokePoints);
  noStroke();
  const labels = ['SPACE', 'ENTER', 'DELETE'];
  const colors = [color(45, 100, 165), color(40, 125, 80), color(155, 55, 65)];
  for (let i = 0; i < 3; i++) {
    fill(colors[i]); rect(x + i * w / 3, y + h, w / 3, w - h);
    fill(255); textAlign(CENTER, CENTER); textSize(w * .085);
    text(labels[i], x + (i + .5) * w / 3, y + h + (w - h) / 2);
  }
  pop();
}

// Sample ink without connecting separate pen strokes; normalize as one shape.
function shapeCloud(strokes) {
  const cloud = [];
  let loX = Infinity, loY = Infinity, hiX = -Infinity, hiY = -Infinity;
  for (const st of strokes) for (const p of st) {
    loX = min(loX, p.x); loY = min(loY, p.y); hiX = max(hiX, p.x); hiY = max(hiY, p.y);
  }
  const scale = max(.001, max(hiX - loX, hiY - loY));
  for (const st of strokes) {
    for (let i = 0; i < st.length; i++) {
      const p = st[i], q = st[max(0, i - 1)];
      const n = max(1, Math.ceil(dist(p.x, p.y, q.x, q.y) / scale * 40));
      for (let j = 0; j <= n; j++) {
        const t = j / n;
        cloud.push({
          x: (lerp(q.x, p.x, t) - (loX + hiX) / 2) / scale,
          y: (lerp(q.y, p.y, t) - (loY + hiY) / 2) / scale,
        });
      }
    }
  }
  return cloud;
}

function nearestMean(a, b) {
  let sum = 0;
  for (const p of a) {
    let best = Infinity;
    for (const q of b) best = Math.min(best, Math.hypot(p.x - q.x, p.y - q.y));
    sum += best;
  }
  return sum / a.length;
}

function recognizeInk() {
  const input = shapeCloud(ink);
  let best = Infinity, letter = 'a';
  for (let i = 0; i < shapeTemplates.length; i++) {
    const t = shapeTemplates[i];
    const score = nearestMean(input, t) + nearestMean(t, input);
    if (score < best) { best = score; letter = shapeLetters[i]; }
  }
  return letter;
}

function addMultiTemplate(letter, coords) {
  const strokes = [];
  for (const xy of coords) {
    const st = [];
    for (let i = 0; i < xy.length; i += 2) st.push({ x: xy[i], y: xy[i + 1] });
    strokes.push(st);
  }
  shapeTemplates.push(shapeCloud(strokes)); shapeLetters.push(letter);
}

function addTemplate(letter, ...xy) {
  addMultiTemplate(letter, [xy]);
}

// Simple one-stroke lowercase shapes. Add more samples after user testing.
function buildTemplates() {
  addTemplate('a', 8,3, 5,1, 1,3, 0,7, 3,9, 7,8, 8,3, 8,10);
  addTemplate('b', 0,0, 0,10, 0,5, 4,4, 8,6, 8,9, 4,10, 0,8);
  addTemplate('c', 8,2, 4,0, 1,2, 0,6, 2,9, 6,10, 8,8);
  addTemplate('d', 8,5, 4,3, 1,5, 0,8, 3,10, 7,9, 8,5, 8,0, 8,10);
  addTemplate('e', 0,5, 8,5, 7,1, 3,0, 0,3, 0,7, 3,10, 8,9);
  addTemplate('f', 7,0, 4,0, 2,3, 2,10, 2,5, 0,5, 6,5);
  addTemplate('g', 8,2, 4,0, 1,2, 0,5, 3,7, 7,6, 8,2, 8,10, 6,13, 2,13, 0,11);
  addTemplate('h', 0,0, 0,10, 0,6, 3,4, 6,4, 8,6, 8,10);
  addTemplate('i', 0,0, 3,2, 1,4, 1,10, 4,10);
  addTemplate('j', 6,0, 6,8, 5,11, 2,12, 0,10);
  addTemplate('k', 0,0, 0,10, 0,6, 7,3, 2,6, 8,10);
  addTemplate('l', 0,0, 0,8, 2,10, 4,10);
  addTemplate('m', 0,10, 0,0, 0,4, 3,0, 5,2, 5,10, 5,4, 8,0, 10,2, 10,10);
  addTemplate('n', 0,10, 0,0, 0,4, 4,0, 8,2, 8,10);
  addTemplate('o', 4,0, 1,1, 0,5, 1,9, 4,10, 7,9, 8,5, 7,1, 4,0);
  addTemplate('p', 0,13, 0,0, 0,2, 4,0, 8,2, 8,5, 4,7, 0,5);
  addTemplate('q', 8,2, 4,0, 1,2, 0,5, 3,7, 7,6, 8,2, 8,13, 10,10);
  addTemplate('r', 0,10, 0,0, 0,4, 4,0, 7,1);
  addTemplate('s', 8,1, 5,0, 1,2, 1,4, 7,6, 8,8, 5,10, 0,9);
  addTemplate('t', 4,0, 4,8, 6,10, 8,9, 4,5, 0,5, 8,5);
  addTemplate('u', 0,0, 0,7, 2,10, 6,10, 8,7, 8,0, 8,10);
  addTemplate('v', 0,0, 4,10, 8,0);
  addTemplate('w', 0,0, 2,10, 5,3, 8,10, 10,0);
  addTemplate('x', 0,0, 8,10, 4,5, 8,0, 0,10);
  addTemplate('y', 0,0, 2,6, 5,7, 8,0, 7,10, 4,13, 1,12);
  addTemplate('z', 0,0, 8,0, 0,10, 8,10);
  // Natural multi-stroke variants (dots and crossbars are separate strokes).
  addMultiTemplate('i', [[3,4, 3,10], [3,1]]);
  addMultiTemplate('j', [[6,4, 6,10, 4,13, 1,12], [6,1]]);
  addMultiTemplate('t', [[4,0, 4,8, 6,10, 8,9], [0,4, 8,4]]);
  addMultiTemplate('x', [[0,0, 8,10], [8,0, 0,10]]);
  addMultiTemplate('f', [[7,0, 4,0, 2,3, 2,10], [0,5, 6,5]]);
  addMultiTemplate('k', [[0,0, 0,10], [7,3, 0,6, 8,10]]);
  // Alternate shapes for commonly written letters.
  addTemplate('l', 0,0, 2,10);
  addTemplate('n', 0,10, 0,0, 4,0, 8,4, 8,10);
  addTemplate('u', 0,0, 0,7, 4,10, 8,7, 8,0);
}
