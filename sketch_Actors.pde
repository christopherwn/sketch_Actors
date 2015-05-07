import java.util.Date;
import java.util.regex.*;
import java.text.*;

int teamCount = 6;
String[] teamNames;
HashMap teamIndices;

static final int ROW_HEIGHT = 23;
static final float HALF_ROW_HEIGHT = ROW_HEIGHT / 2.0f;

static final int SIDE_PADDING = 30;
static final int TOP_PADDING = 40;

SalaryList salaries;
StandingsList standings;

StandingsList[] season;
Integrator[] standingsPosition;

PFont font;

String firstDateStamp = "20090601";
String lastDateStamp = "20130601";
String todayDateStamp;

static final long MILLIS_PER_DAY = 24 * 60 * 60 * 1000;


int dateCount;
int dateIndex;
int minDateIndex = 0;  
int maxDateIndex;

String[] dateStamp;
String[] datePretty;

void setupDates() {
  try {
    Date firstDate = stampFormat.parse(firstDateStamp);
    long firstDateMillis = firstDate.getTime();
    Date lastDate = stampFormat.parse(lastDateStamp);
    long lastDateMillis = lastDate.getTime();

    dateCount = (int) 
      ((lastDateMillis - firstDateMillis) / MILLIS_PER_DAY) + 1;      
    maxDateIndex = dateCount;
    dateStamp = new String[dateCount];
    datePretty = new String[dateCount];

    todayDateStamp = year() + nf(month(), 2) + nf(day(), 2);

      
    for (int i = 0; i < dateCount; i++) {
      Date date = new Date(firstDateMillis + MILLIS_PER_DAY*i);
      datePretty[i] = prettyFormat.format(date);
      dateStamp[i] = stampFormat.format(date);
      if (dateStamp[i].equals(todayDateStamp)) {
        maxDateIndex = i-1;
      }
    }
  } catch (ParseException e) {
    die("Problem while setting up dates", e);
  }
}  
public void setup() {
  size(480, 550);
  setupSalaries();
  setupStandings();
  setupRanking();
  
  font = createFont("Georgia", 12);
  textFont(font);

  frameRate(15);
}

void setupTeams() {
  String[] lines = loadStrings("Data2.tsv");
    
  teamCount = lines.length;
  teamCodes = new String[teamCount];
  teamNames = new String[teamCount];
  teamIndices = new HashMap();
    
  for (int i = 0; i < teamCount; i++) {
    String[] pieces = split(lines[i], TAB);
    teamCodes[i] = pieces[0];
    teamNames[i] = pieces[1];
    teamIndices.put(teamCodes[i], new Integer(i));
  }
}

void setupSalaries() {
  String[] lines = loadStrings("Data2.tsv");
  salaries = new SalaryList(lines);
}

void setupRanking() {
  standingsPosition = new Integrator[teamCount];
  for (int i = 0; i < teamCodes.length; i++) {
    standingsPosition[i] = new Integrator(i);
  }
}
public void draw() {
  background(255);
  smooth();

  drawDateSelector();

  translate(SIDE_PADDING, TOP_PADDING);
  
  boolean updated = false;
  for (int i = 0; i < teamCount; i++) {
    if (standingsPosition[i].update()) {
      updated = true;
    }
  }
  if (!updated) {
    noLoop();
  }

  for (int i = 0; i < teamCount; i++) {
    //float standingsY = standings.getRank(i)*ROW_HEIGHT + HALF_ROW_HEIGHT;
    float standingsY = standingsPosition[i].value * ROW_HEIGHT + HALF_ROW_HEIGHT;

    image(logos[i], 0, standingsY - logoHeight/2, logoWidth, logoHeight);
    
        float weight = map(salaries.getValue(i), 
                       salaries.getMinValue(), salaries.getMaxValue(), 
                       0.25f, 6);
    strokeWeight(weight);
      
    float salaryY = salaries.getRank(i)*ROW_HEIGHT + HALF_ROW_HEIGHT;
    if (salaryY >= standingsY) {
      stroke(33, 85, 156);  // Blue for positive (or equal) difference.
    } else {
      stroke(206, 0, 82);   // Red for wasting money.
    }
      
    line(160, standingsY, 325, salaryY);

    fill(128);
    textAlign(LEFT, CENTER);
    text(salaries.getTitle(i), 335, salaryY);
  }
}

int dateSelectorX;
int dateSelectorY = 30;

// Draw a series of lines for selecting the date
void drawDateSelector() {
  dateSelectorX = (width - dateCount*2) / 2;

  strokeWeight(1);
  for (int i = 0; i < dateCount; i++) {
    int x = dateSelectorX + i*2;

    // If this is the currently selected date, draw it differently
    if (i == dateIndex) {
      stroke(0);
      line(x, 0, x, 13);
      textAlign(CENTER, TOP);
      text(datePretty[dateIndex], x, 15);

    } else {
      // If this is a viewable date, make the line darker
      if ((i >= minDateIndex) && (i <= maxDateIndex)) {
        stroke(128);  // Viewable date
      } else {
        stroke(204);  // Not a viewable date
      }
      line(x, 0, x, 7);
    }
  }
}


void setDate(int index) {
  dateIndex = index;
  standings = season[dateIndex];

  for (int i = 0; i < teamCount; i++) {
    standingsPosition[i].target(standings.getRank(i));
  }
  // Re-enable the animation loop
  loop();
}

void keyPressed(){
  if (key == CODED) {
    if (keyCode == LEFT) {
      int newDate = max(dateIndex - 1, minDateIndex);
      setDate(newDate);

    } else if (keyCode == RIGHT) {
      int newDate = min(dateIndex + 1, maxDateIndex);
      setDate(newDate);
    }
  }
}  
  
class SalaryList extends RankedList {
    
  SalaryList(String[] lines) {
    super(teamCount, false);
    
    for (int i = 0; i < teamCount; i++) {
      String pieces[] = split(lines[i], TAB);
        
      // First column is the team 2-3 digit team code.
      int index = teamIndex(pieces[0]);
        
      // Second column is the salary as a number. 
      value[index] = parseInt(pieces[1]);
        
      // Make the title in the format $NN,NNN,NNN
      int salary = (int) value[index];
      title[index] = "$" + nfc(salary);
    }
    update();
  }
}  
