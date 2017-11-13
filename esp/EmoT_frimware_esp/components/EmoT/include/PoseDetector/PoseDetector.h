class PoseDetector {

  public:
 enum Pose {question,vsign,arm,standing,beer,sushi};
 static double classify(int i[5])
     {

    double p = -1;
    p = PoseDetector::N463432240(i);
    return p;
  }
  static double N463432240(int i[5]) {
    double p = -1;
    if (i[4] == 0) {
      p = 1;
    } else if (i[4] <= 12693.0) {
    p = PoseDetector::Ncc7fd7e1(i);
    } else if (i[4] > 12693.0) {
    p = PoseDetector::N3290dd1b4(i);
    } 
    return p;
  }
  static double Ncc7fd7e1(int i[5]) {
    double p = -1;
    if (i[1] == 0) {
      p = 2;
    } else if (i[1] <= 7754.0) {
    p = PoseDetector::N1dd361c02(i);
    } else if (i[1] > 7754.0) {
    p = PoseDetector::N20b6938c3(i);
    } 
    return p;
  }
  static double N1dd361c02(int i[5]) {
    double p = -1;
    if (i[2] == 0) {
      p = 3;
    } else if (i[2] <= 12174.0) {
      p = 3;
    } else if (i[2] > 12174.0) {
      p = 2;
    } 
    return p;
  }
  static double N20b6938c3(int i[5]) {
    double p = -1;
    if (i[2] == 0) {
      p = 5;
    } else if (i[2] <= 11769.0) {
      p = 5;
    } else if (i[2] > 11769.0) {
      p = 1;
    } 
    return p;
  }
  static double N3290dd1b4(int i[5]) {
    double p = -1;
    if (i[1] == 0) {
      p = 4;
    } else if (i[1] <= 7754.0) {
      p = 4;
    } else if (i[1] > 7754.0) {
      p = 0;
    } 
    return p;
  }
}
;