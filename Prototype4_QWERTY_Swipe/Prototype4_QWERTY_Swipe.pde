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

// Prototype 4: QWERTY tap and deliberate swipe input.
String[] rows = {"qwertyuiop", "asdfghjkl", "zxcvbnm"};
int dwellMillis = 90;
boolean swiping = false;
String swipeText = "";
String hoverLetter = "";
int hoverSince = 0;
boolean hoverRecorded = false;

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

// All keyboard geometry is relative to the calibrated one-inch square.
float leftEdge() { return width/2.0f-sizeOfInputArea/2; }
float topEdge() { return height/2.0f-sizeOfInputArea/2; }
float keyWidth() { return sizeOfInputArea/10; }
float rowHeight() { return sizeOfInputArea*.23f; }
float rowLeft(int r) { return width/2.0f-rows[r].length()*keyWidth()/2; }
float rowTop(int r) { return topEdge()+sizeOfInputArea*0.09+r*rowHeight(); }

String letterAt(float x,float y) {
  for (int r=0;r<rows.length;r++) {
    float dx=x-rowLeft(r), dy=y-rowTop(r);
    if (dx>=0 && dx<rows[r].length()*keyWidth() && dy>=0 && dy<rowHeight())
      return rows[r].substring(int(dx/keyWidth()), int(dx/keyWidth())+1);
  }
  return "";
}

void drawKeyboard() {
  if (swiping) updateSwipe();
  float s=sizeOfInputArea, x=leftEdge(), y=topEdge();
  pushStyle();
  noStroke();
  fill(32,36,43); rect(x,y,s,s);
  textAlign(CENTER,CENTER);
  fill(255); textSize(s*0.065);
  String preview=swipeText;
  if (preview.length()>14) preview=preview.substring(preview.length()-14);
  text(preview,x+s/2,y+s*0.045);
  for (int r=0;r<rows.length;r++) {
    for (int i=0;i<rows[r].length();i++) {
      String c=rows[r].substring(i, i+1);
      float kx=rowLeft(r)+i*keyWidth(), ky=rowTop(r);
      fill(swiping && c.equals(hoverLetter) ? color(37,99,235) : color(65,75,89));
      rect(kx+.5f,ky+.5f,keyWidth()-1,rowHeight()-1,2);
      fill(255); textSize(s*0.075);
      text(c,kx+keyWidth()/2,ky+rowHeight()/2);
    }
  }
  fill(52,93,151); rect(x+1,y+s*.79f,s*.70f-2,s*.21f-1,3);
  fill(149,63,70); rect(x+s*.70f+1,y+s*.79f,s*.30f-2,s*.21f-1,3);
  fill(255); textSize(s*0.085);
  text("SPACE",x+s*.35f,y+s*.895f);
  text("DEL",x+s*.85f,y+s*.895f);
  popStyle();
}

boolean didMouseClick(float x,float y,float w,float h) {
  return mouseX>=x && mouseX<x+w && mouseY>=y && mouseY<y+h;
}

void resetSwipe() {
  swiping=false; swipeText=""; hoverLetter=""; hoverRecorded=false;
}

void recordLetter(String c) {
  if(c.length()>0) swipeText+=c;
  hoverRecorded=true;
}

// Pausing briefly on an intermediate key selects it; passing over keys does not.
void updateSwipe() {
  String c=letterAt(mouseX,mouseY);
  if(!c.equals(hoverLetter)) {
    hoverLetter=c; hoverSince=millis(); hoverRecorded=false;
  }
  if(c.length()>0 && !hoverRecorded && millis()-hoverSince>=dwellMillis) recordLetter(c);
}

void mousePressed() {
  if (finishTime!=0 || startTime==0) return;
  resetSwipe();
  if (didMouseClick(600,600,200,200)) { nextTrial(); return; }
  float x=leftEdge(),y=topEdge(),s=sizeOfInputArea;
  if(didMouseClick(x,y+s*.79f,s*.70f,s*.21f)) { currentTyped+=" "; return; }
  if(didMouseClick(x+s*.70f,y+s*.79f,s*.30f,s*.21f)) {
    if(currentTyped.length()>0) currentTyped=currentTyped.substring(0,currentTyped.length()-1);
    return;
  }
  String c=letterAt(mouseX,mouseY);
  if(c.length()>0) {
    swiping=true; hoverLetter=c; hoverSince=millis(); recordLetter(c);
  }
}

void mouseDragged() { if(swiping) updateSwipe(); }

void mouseReleased() {
  if(!swiping) return;
  updateSwipe();
  if(hoverLetter.length()>0 && finishTime==0) {
    if(!hoverRecorded) recordLetter(hoverLetter);
    currentTyped+=swipeText;
  }
  resetSwipe();
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