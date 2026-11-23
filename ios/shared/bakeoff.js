const SHARED = '../shared/';

const DPIofYourDeviceScreen = urlNumber('ppi', defaultPointsPerInch());
const sizeOfInputArea = DPIofYourDeviceScreen * 1; //aka, 1.0 inches square!

let phrases = []; //contains all of the phrases
let totalTrialNum = urlNumber('trials', 2); //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
let currTrialNum = 0; // the current trial number (indexes into trials array above)
let startTime = 0; // time starts when the first letter is entered
let finishTime = 0; // records the time of when the final trial ends
let lastTime = 0; //the timestamp of when the last trial was completed
let lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
let lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
let errorsTotal = 0; //a running total of the number of errors (when hitting next)
let currentPhrase = ''; //the current target phrase
let currentTyped = ''; //what the user has typed so far
let watch;
let phraseLines;

let pointerX = 0;
let pointerY = 0;
let pointerIsDown = false;
let activePointerId = null;
let safeInsets = { top: 0, right: 0, bottom: 0, left: 0 };

function urlNumber(name, fallback) {
  const value = parseFloat(new URLSearchParams(window.location.search).get(name));
  return value > 0 ? value : fallback;
}

function defaultPointsPerInch() {
  const ua = navigator.userAgent;
  const iPad = /iPad/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (iPad) return 132;
  if (/iPhone|iPod/.test(ua)) return 153;
  return 120;
}

function preload() {
  watch = loadImage(SHARED + 'watchhand3smaller.png');
  phraseLines = loadStrings(SHARED + 'phrases2.txt');
}

function bakeoffSetup() {
  phrases = phraseLines.join('\n').split(/\r\n|\r|\n/).filter(p => p.trim().length > 0);
  shuffle(phrases, true); //randomize the order of the phrases with no seed
  totalTrialNum = min(totalTrialNum, phrases.length);

  const canvas = createCanvas(windowWidth, windowHeight);
  attachPointerInput(canvas.elt);
  readSafeInsets();
  textFont('Arial');
  noStroke();
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
  readSafeInsets();
}

function attachPointerInput(elt) {
  const update = e => {
    const r = elt.getBoundingClientRect();
    pointerX = e.clientX - r.left;
    pointerY = e.clientY - r.top;
  };
  const call = name => {
    if (typeof window[name] === 'function') window[name]();
  };

  elt.addEventListener('pointerdown', e => {
    if (activePointerId !== null || (e.pointerType === 'mouse' && e.button !== 0)) return;
    e.preventDefault();
    activePointerId = e.pointerId;
    try { elt.setPointerCapture(e.pointerId); } catch (err) {}
    update(e);
    pointerIsDown = true;
    keepScreenAwake();
    call('pointerPressed');
  });
  elt.addEventListener('pointermove', e => {
    if (e.pointerId !== activePointerId) return;
    e.preventDefault();
    update(e);
    call('pointerDragged');
  });
  const end = e => {
    if (e.pointerId !== activePointerId) return;
    e.preventDefault();
    if (e.type === 'pointerup') update(e);
    pointerIsDown = false;
    activePointerId = null;
    call('pointerReleased');
  };
  elt.addEventListener('pointerup', end);
  elt.addEventListener('pointercancel', end);
  elt.addEventListener('contextmenu', e => e.preventDefault());
  document.addEventListener('gesturestart', e => e.preventDefault());
}

function didTouch(x, y, w, h) {
  return pointerX >= x && pointerX < x + w && pointerY >= y && pointerY < y + h;
}

let wakeLock = null;
async function keepScreenAwake() {
  if (wakeLock || !('wakeLock' in navigator)) return;
  try {
    wakeLock = await navigator.wakeLock.request('screen');
    wakeLock.addEventListener('release', () => { wakeLock = null; });
  } catch (err) {}
}

function readSafeInsets() {
  let probe = document.getElementById('safe-area-probe');
  if (!probe) {
    probe = document.createElement('div');
    probe.id = 'safe-area-probe';
    document.body.appendChild(probe);
  }
  const cs = getComputedStyle(probe);
  safeInsets = {
    top: parseFloat(cs.paddingTop) || 0,
    right: parseFloat(cs.paddingRight) || 0,
    bottom: parseFloat(cs.paddingBottom) || 0,
    left: parseFloat(cs.paddingLeft) || 0,
  };
}

function inputX() { return width / 2 - sizeOfInputArea / 2; }
function inputY() { return height / 2 - sizeOfInputArea / 2; }

//You are allowed to have a next button outside the 1" area
function nextButton() {
  const s = constrain(min(width, height) * 0.3, 90, 200);
  return { x: width - s - safeInsets.right, y: height - s - safeInsets.bottom, w: s, h: s };
}

function inNextButton() {
  const b = nextButton();
  return didTouch(b.x, b.y, b.w, b.h);
}

function drawNextButton() {
  const b = nextButton();
  push();
  noStroke();
  fill(255, 0, 0);
  rect(b.x, b.y, b.w, b.h);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(20);
  text('NEXT >', b.x + b.w / 2, b.y + b.h / 2);
  pop();
}

function fitTextSize(str, maxW, base) {
  textSize(base);
  const w = textWidth(str);
  return w > maxW ? base * maxW / w : base;
}

function drawTrialHeader() {
  const m = 16;
  const x = safeInsets.left + m;
  let y = safeInsets.top + m;
  const maxW = width > height
    ? inputX() - x - m
    : width - x - safeInsets.right - m;
  const typed = currentTyped + '|';
  const size = min(fitTextSize(currentPhrase, maxW, 20), fitTextSize(typed, maxW, 20));

  push();
  noStroke();
  fill(255, 230);
  rect(x - 8, y - 8, maxW + 16, 26 + 19 + size + 12 + 19 + size + 16, 8);
  textAlign(LEFT, TOP);
  fill(110);
  textSize(15);
  text('Phrase ' + (currTrialNum + 1) + ' of ' + totalTrialNum, x, y);
  y += 26;
  text('Target:', x, y);
  y += 19;
  fill(30);
  textSize(size);
  text(currentPhrase, x, y); //draw the target string
  y += size + 12;
  fill(110);
  textSize(15);
  text('Entered:', x, y);
  y += 19;
  fill(30);
  textSize(size);
  text(typed, x, y); //draw what the user has entered thus far
  pop();
}

function drawStartMessage(msg) {
  push();
  noStroke();
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(sizeOfInputArea * 0.11);
  text(msg, width / 2, height / 2);
  pop();
}

//probably shouldn't touch this - should be same for all teams.
function drawWatch() {
  const watchscale = DPIofYourDeviceScreen / 138.0; //normalizes the image size
  push();
  translate(width / 2, height / 2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  pop();
}

function drawResults() {
  const wpm = (lettersEnteredTotal / 5.0) / ((finishTime - startTime) / 60000); //FYI - 60K is number of milliseconds in minute
  const freebieErrors = lettersExpectedTotal * .05; //no penalty if errors are under 5% of chars
  const penalty = max(errorsTotal - freebieErrors, 0) * .5;
  const lines = [
    'Trials complete!',
    'Total time taken: ' + (finishTime - startTime),
    'Total letters entered: ' + lettersEnteredTotal,
    'Total letters expected: ' + lettersExpectedTotal,
    'Total errors entered: ' + errorsTotal,
    'Raw WPM: ' + wpm,
    'Freebie errors: ' + nf(freebieErrors, 1, 3),
    'Penalty: ' + penalty,
    'WPM w/ penalty: ' + (wpm - penalty), //yes, minus, because higher WPM is better
  ];
  push();
  noStroke();
  fill(0);
  textAlign(CENTER, BASELINE);
  textSize(min(20, width / 22));
  const lineHeight = textSize() * 1.4;
  let y = max(height * 0.25, safeInsets.top + 40);
  for (const line of lines) {
    text(line, width / 2, y);
    y += lineHeight;
  }
  pop();
}

function nextTrial() {
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime != 0 && finishTime == 0) { //in the middle of trials
    const errors = computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
    console.log('==================');
    console.log('Phrase ' + (currTrialNum + 1) + ' of ' + totalTrialNum);
    console.log('Target phrase: ' + currentPhrase);
    console.log('Phrase length: ' + currentPhrase.length);
    console.log('User typed: ' + currentTyped);
    console.log('User typed length: ' + currentTyped.length);
    console.log('Number of errors: ' + errors); //trim whitespace and compute errors
    console.log('Time taken on this trial: ' + (Math.floor(millis()) - lastTime));
    console.log('Time taken since beginning: ' + (Math.floor(millis()) - startTime));
    console.log('==================');
    lettersExpectedTotal += currentPhrase.trim().length;
    lettersEnteredTotal += currentTyped.trim().length;
    errorsTotal += errors;
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (startTime != 0 && currTrialNum == totalTrialNum - 1) { //check to see if experiment just finished
    finishTime = Math.floor(millis());
    const wpm = (lettersEnteredTotal / 5.0) / ((finishTime - startTime) / 60000);
    const freebieErrors = lettersExpectedTotal * .05;
    const penalty = max(errorsTotal - freebieErrors, 0) * .5;
    console.log('==================');
    console.log('Trials complete!');
    console.log('Total time taken: ' + (finishTime - startTime));
    console.log('Total letters entered: ' + lettersEnteredTotal);
    console.log('Total letters expected: ' + lettersExpectedTotal);
    console.log('Total errors entered: ' + errorsTotal);
    console.log('Raw WPM: ' + wpm);
    console.log('Freebie errors: ' + freebieErrors);
    console.log('Penalty: ' + penalty);
    console.log('WPM w/ penalty: ' + (wpm - penalty));
    console.log('==================');

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime == 0) { //first trial starting now
    console.log('Trials beginning! Starting timer...');
    startTime = Math.floor(millis()); //start the timer!
  } else {
    currTrialNum++; //increment trial number
  }

  lastTime = Math.floor(millis()); //record the time of when this trial ended
  currentTyped = ''; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = 'abc'; // uncomment this to override the test phrase (useful for debugging)
}

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
function computeLevenshteinDistance(phrase1, phrase2) { //this computes error between two strings
  const distance = [];
  for (let i = 0; i <= phrase1.length; i++) distance.push(new Array(phrase2.length + 1).fill(0));

  for (let i = 0; i <= phrase1.length; i++)
    distance[i][0] = i;
  for (let j = 1; j <= phrase2.length; j++)
    distance[0][j] = j;

  for (let i = 1; i <= phrase1.length; i++)
    for (let j = 1; j <= phrase2.length; j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length][phrase2.length];
}
