String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
int DPIofYourDeviceScreen = 120; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
PImage finger;

//Variables for my silly implementation. You can delete this:
String alphabet = "abcdefghijklmnopqrstuvwxyz";
int selectedKey = -1;
boolean selectingLetter = false;

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  //randomSeed(100); //randomize the order of the phrases with seed 100; same order every time, useful for testing
  //randomize the order of the phrases with no seed
  for (int i = phrases.length - 1; i > 0; i--) {
    int j = int(random(i + 1));
    String tmp = phrases[i];
    phrases[i] = phrases[j];
    phrases[j] = tmp;
  }
 
  //orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  textFont(createFont("Arial", 20)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
  textAlign(LEFT, BASELINE);
  background(255); //clear background
  
   //check to see if the user finished. You can't change the score computation.
  if (finishTime!=0)
  {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!",400,200); //output
    text("Total time taken: " + (finishTime - startTime),400,220); //output
    text("Total letters entered: " + lettersEnteredTotal,400,240); //output
    text("Total letters expected: " + lettersExpectedTotal,400,260); //output
    text("Total errors entered: " + errorsTotal,400,280); //output
    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    text("Raw WPM: " + wpm,400,300); //output
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    text("Freebie errors: " + nf(freebieErrors,1,3),400,320); //output
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    text("Penalty: " + penalty,400,340);
    text("WPM w/ penalty: " + (wpm-penalty),400,360); //yes, minus, because higher WPM is better
    return;
  }
  
  drawWatch(); //draw watch background
  fill(100);
  rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"
  

  if (startTime==0 && !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); //display this messsage until the user clicks!
  }

  if (startTime==0 && mousePressed)
  {
    nextTrial(); //start the trials!
  }

  if (startTime!=0)
  {
    //feel free to change the size and position of the target/entered phrases and next button 
    textAlign(LEFT); //align the text left
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + currentTyped +"|", 70, 140); //draw what the user has entered thus far 

    //draw very basic next button
    fill(255, 0, 0);
    rect(600, 600, 200, 200); //draw next button
    fill(255);
    text("NEXT > ", 650, 650); //draw next label

    drawKeyboard();
  }
 
 
  //drawFinger(); //no longer needed as we'll be deploying to an actual touschreen device
}

// Circular keyboard; all dimensions are relative to the calibrated inch.
float outerRadius() { return sizeOfInputArea * .48f; }
float innerRadius() { return sizeOfInputArea * .30f; }

int letterAt(float x, float y) {
  float dx = x-width/2.0f, dy = y-height/2.0f;
  float r = sqrt(dx*dx+dy*dy);
  if (r < innerRadius() || r > outerRadius()) return -1;
  float step = TWO_PI/26.0f;
  float angle = (atan2(dy,dx)+HALF_PI+step/2+TWO_PI)%TWO_PI;
  return int(angle/step)%26;
}

void drawKeyboard() {
  float cx=width/2.0f, cy=height/2.0f, s=sizeOfInputArea;
  float step=TWO_PI/26.0f, ro=outerRadius(), ri=innerRadius();
  pushStyle();
  noStroke();
  fill(32,36,43);
  rect(cx-s/2,cy-s/2,s,s);
  textAlign(CENTER,CENTER);
  for (int i=0; i<26; i++) {
    float angle=-HALF_PI+i*step;
    fill(i==selectedKey ? color(37,99,235) : color(57,67,81));
    stroke(32,36,43);
    strokeWeight(1);
    beginShape();
    for (int j=0;j<=8;j++) {
      float t=angle-step/2+step*j/8;
      vertex(cx+ro*cos(t),cy+ro*sin(t));
    }
    for (int j=8;j>=0;j--) {
      float t=angle-step/2+step*j/8;
      vertex(cx+ri*cos(t),cy+ri*sin(t));
    }
    endShape(CLOSE);
    noStroke();
    fill(255);
    textSize(s*0.073);
    text(alphabet.substring(i, i+1),cx+(ro+ri)/2*cos(angle),cy+(ro+ri)/2*sin(angle));
  }
  float bw=s*.40f, bh=s*.16f;
  fill(52,93,151);
  rect(cx-bw/2,cy-s*.18f,bw,bh,4);
  fill(149,63,70);
  rect(cx-bw/2,cy+s*0.02,bw,bh,4);
  fill(255);
  textSize(s*0.088);
  text("SPACE",cx,cy-s*.10f);
  text("DELETE",cx,cy+s*.10f);
  popStyle();
}

boolean didMouseClick(float x,float y,float w,float h) {
  return mouseX>=x && mouseX<x+w && mouseY>=y && mouseY<y+h;
}

void mousePressed() {
  if (finishTime!=0 || startTime==0) return;
  if (didMouseClick(600,600,200,200)) {
    selectingLetter=false;
    selectedKey=-1;
    nextTrial();
    return;
  }
  float cx=width/2.0f, cy=height/2.0f, s=sizeOfInputArea;
  if (didMouseClick(cx-s*.20f,cy-s*.18f,s*.40f,s*.16f)) {
    currentTyped+=" ";
  } else if (didMouseClick(cx-s*.20f,cy+s*0.02,s*.40f,s*.16f)) {
    if (currentTyped.length()>0) currentTyped=currentTyped.substring(0,currentTyped.length()-1);
  } else {
    selectedKey=letterAt(mouseX,mouseY);
    selectingLetter=selectedKey>=0;
  }
}

void mouseDragged() {
  if (selectingLetter) selectedKey=letterAt(mouseX,mouseY);
}

void mouseReleased() {
  if (!selectingLetter) return;
  int k=letterAt(mouseX,mouseY);
  if (k>=0 && finishTime==0) currentTyped+=alphabet.substring(k, k+1);
  selectedKey=-1;
  selectingLetter=false;
}

void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    println("==================");
    println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    println("Target phrase: " + currentPhrase); //output
    println("Phrase length: " + currentPhrase.length()); //output
    println("User typed: " + currentTyped); //output
    println("User typed length: " + currentTyped.length()); //output
    println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    println("Time taken on this trial: " + (millis()-lastTime)); //output
    println("Time taken since beginning: " + (millis()-startTime)); //output
    println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    println("==================");
    println("Trials complete!"); //output
    println("Total time taken: " + (finishTime - startTime)); //output
    println("Total letters entered: " + lettersEnteredTotal); //output
    println("Total letters expected: " + lettersExpectedTotal); //output
    println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    println("Raw WPM: " + wpm); //output
    println("Freebie errors: " + freebieErrors); //output
    println("Penalty: " + penalty);
    println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } 
  else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}

//probably shouldn't touch this - should be same for all teams.
void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0; //normalizes the image size
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}

//probably shouldn't touch this - should be same for all teams.
void drawFinger()
{
  float fingerscale = DPIofYourDeviceScreen/150f; //normalizes the image size
  pushMatrix();
  translate(mouseX, mouseY);
  scale(fingerscale);
  imageMode(CENTER);
  image(finger,52,341);
  if (mousePressed)
     fill(0);
  else
     fill(255);
  ellipse(0,0,5,5);

  popMatrix();
  }
  

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}