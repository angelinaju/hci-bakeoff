import java.util.Arrays;
import java.util.Collections;
import java.util.Random;

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
final int DPIofYourDeviceScreen = 120; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
PImage finger;

//Variables for my silly implementation. You can delete this:
// Handwriting input accepts multiple strokes; ENTER commits the letter.
ArrayList<PVector> strokePoints = new ArrayList<PVector>();
ArrayList<ArrayList<PVector>> ink = new ArrayList<ArrayList<PVector>>();
ArrayList<ArrayList<PVector>> shapeTemplates = new ArrayList<ArrayList<PVector>>();
ArrayList<Character> shapeLetters = new ArrayList<Character>();
boolean drawingLetter = false;
boolean outsidePad = false;

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing
 
  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 20)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
  buildTemplates();
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
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
  

  if (startTime==0 & !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    textSize(sizeOfInputArea*.10f);
    text("Tap to start", width/2, height/2);
    textSize(20); //display this messsage until the user clicks!
  }

  // The first click now starts the trials in mousePressed().

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

    //example design draw code
    drawWritingPad();
  }
 
 
  //drawFinger(); //no longer needed as we'll be deploying to an actual touschreen device
}

//my terrible implementation you can entirely replace
boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX<x+w && mouseY>y && mouseY<y+h); //check to see if it is in button bounds
}

//my terrible implementation you can entirely replace
void mousePressed()
{
  if (finishTime != 0) return;
  if (startTime == 0) {
    if (didMouseClick(padX(), padY(), sizeOfInputArea, sizeOfInputArea)) nextTrial();
    return;
  }

  //You are allowed to have a next button outside the 1" area
  if (didMouseClick(600, 600, 200, 200)) {
    clearInk();
    nextTrial(); //if so, advance to next trial
    return;
  }

  float x = padX();
  float y = padY();
  float w = sizeOfInputArea;
  float h = w * .75f;

  if (didMouseClick(x, y+h, w/3, w-h)) {
    if (ink.isEmpty()) currentTyped += " ";
  } else if (didMouseClick(x+w/3, y+h, w/3, w-h)) {
    if (!ink.isEmpty()) {
      currentTyped += recognizeInk();
      clearInk();
    }
  } else if (didMouseClick(x+2*w/3, y+h, w/3, w-h)) {
    if (!ink.isEmpty()) clearInk();
    else if (currentTyped.length() > 0)
      currentTyped = currentTyped.substring(0, currentTyped.length()-1);
  } else if (inWritingPad()) {
    strokePoints = new ArrayList<PVector>();
    drawingLetter = true;
    outsidePad = false;
    strokePoints.add(new PVector(mouseX, mouseY));
  }
}

void clearInk() {
  ink.clear();
  strokePoints.clear();
  drawingLetter = false;
  outsidePad = false;
}

float padX() { return width/2-sizeOfInputArea/2; }
float padY() { return height/2-sizeOfInputArea/2; }

boolean inWritingPad() {
  return didMouseClick(padX(), padY(), sizeOfInputArea, sizeOfInputArea*.75f);
}

void mouseDragged() {
  if (!drawingLetter) return;
  // Cancel strokes that leave the writing area instead of accepting outside input.
  if (!inWritingPad()) {
    outsidePad = true;
    return;
  }
  if (!outsidePad) strokePoints.add(new PVector(mouseX, mouseY));
}

void mouseReleased() {
  if (!drawingLetter) return;
  drawingLetter = false;
  if (!outsidePad && inWritingPad()) {
    strokePoints.add(new PVector(mouseX, mouseY));
    ink.add(strokePoints);
  }
  strokePoints = new ArrayList<PVector>();
}

void drawInkStroke(ArrayList<PVector> points, float x, float y, float w, float h) {
  for (int i=0; i<points.size(); i++) {
    PVector p=points.get(i), q=points.get(max(0,i-1));
    int steps=max(1,ceil(PVector.dist(p,q)));
    for (int j=0;j<=steps;j++) {
      float px=lerp(q.x,p.x,j/(float)steps), py=lerp(q.y,p.y,j/(float)steps);
      rect(constrain(px-1,x,x+w-2),constrain(py-1,y,y+h-2),2,2);
    }
  }
}

void drawWritingPad() {
  float x=padX(), y=padY(), w=sizeOfInputArea, h=w*.75f;
  noStroke(); fill(35); rect(x,y,w,h);
  if (!drawingLetter && ink.isEmpty()) {
    fill(180); textAlign(CENTER,CENTER); textSize(w*.10f);
    text("draw a letter",x+w/2,y+h/2);
  }
  fill(100,190,255);
  for (ArrayList<PVector> pts : ink) drawInkStroke(pts,x,y,w,h);
  if (drawingLetter && !outsidePad) drawInkStroke(strokePoints,x,y,w,h);
  String[] labels={"SPACE","ENTER","DELETE"};
  int[] colors={color(45,100,165),color(40,125,80),color(155,55,65)};
  for (int i=0;i<3;i++) {
    fill(colors[i]); rect(x+i*w/3,y+h,w/3,w-h);
    fill(255); textAlign(CENTER,CENTER); textSize(w*.085f);
    text(labels[i],x+(i+.5f)*w/3,y+h+(w-h)/2);
  }
  textSize(20); textAlign(LEFT,BASELINE);
}

// Sample ink without connecting separate pen strokes; normalize as one shape.
ArrayList<PVector> shapeCloud(ArrayList<ArrayList<PVector>> strokes) {
  ArrayList<PVector> cloud=new ArrayList<PVector>();
  float loX=Float.MAX_VALUE,loY=Float.MAX_VALUE,hiX=-Float.MAX_VALUE,hiY=-Float.MAX_VALUE;
  for (ArrayList<PVector> st : strokes) for(PVector p:st) {
    loX=min(loX,p.x); loY=min(loY,p.y); hiX=max(hiX,p.x); hiY=max(hiY,p.y);
  }
  float scale=max(.001f,max(hiX-loX,hiY-loY));
  for (ArrayList<PVector> st:strokes) {
    for(int i=0;i<st.size();i++) {
      PVector p=st.get(i),q=st.get(max(0,i-1));
      int n=max(1,ceil(PVector.dist(p,q)/scale*40));
      for(int j=0;j<=n;j++) {
        float t=j/(float)n;
        cloud.add(new PVector((lerp(q.x,p.x,t)-(loX+hiX)/2)/scale,(lerp(q.y,p.y,t)-(loY+hiY)/2)/scale));
      }
    }
  }
  return cloud;
}

float nearestMean(ArrayList<PVector> a,ArrayList<PVector> b) {
  float sum=0;
  for(PVector p:a) {
    float best=Float.MAX_VALUE;
    for(PVector q:b) best=min(best,PVector.dist(p,q));
    sum+=best;
  }
  return sum/a.size();
}

char recognizeInk() {
  ArrayList<PVector> input=shapeCloud(ink);
  float best=Float.MAX_VALUE; char letter='a';
  for(int i=0;i<shapeTemplates.size();i++) {
    ArrayList<PVector> t=shapeTemplates.get(i);
    float score=nearestMean(input,t)+nearestMean(t,input);
    if(score<best) {best=score;letter=shapeLetters.get(i);}
  }
  return letter;
}

void addMultiTemplate(char letter,float[][] coords) {
  ArrayList<ArrayList<PVector>> strokes=new ArrayList<ArrayList<PVector>>();
  for(float[] xy:coords) {
    ArrayList<PVector> st=new ArrayList<PVector>();
    for(int i=0;i<xy.length;i+=2) st.add(new PVector(xy[i],xy[i+1]));
    strokes.add(st);
  }
  shapeTemplates.add(shapeCloud(strokes)); shapeLetters.add(letter);
}

void addTemplate(char letter, float... xy) {
  addMultiTemplate(letter, new float[][] {xy});
}

// Simple one-stroke lowercase shapes. Add more samples after user testing.
void buildTemplates() {
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
  addMultiTemplate('i',new float[][] {{3,4,3,10},{3,1}});
  addMultiTemplate('j',new float[][] {{6,4,6,10,4,13,1,12},{6,1}});
  addMultiTemplate('t',new float[][] {{4,0,4,8,6,10,8,9},{0,4,8,4}});
  addMultiTemplate('x',new float[][] {{0,0,8,10},{8,0,0,10}});
  addMultiTemplate('f',new float[][] {{7,0,4,0,2,3,2,10},{0,5,6,5}});
  addMultiTemplate('k',new float[][] {{0,0,0,10},{7,3,0,6,8,10}});
  // Alternate shapes for commonly written letters.
  addTemplate('l', 0,0, 2,10);
  addTemplate('n', 0,10, 0,0, 4,0, 8,4, 8,10);
  addTemplate('u', 0,0, 0,7, 4,10, 8,7, 8,0);
}

void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (startTime!=0 && currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
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