import 'package:intl/intl.dart';

class DateTimeHelper {

  static String getDayName(int day) {
    switch(day){
      case 1:{return "Monday";}
      case 2:{return "Tuesday";}
      case 3:{return "Wednesday";}
      case 4:{return "Thursday";}
      case 5:{return "Friday";}
      case 6:{return "Saturday";}
      case 7:{return "Sunday";}
      default:{return "--";}
    }

  }
  static  getDataFormatWithTime(String? createdAt) {
    String dateString="";
    final newData=DateTime.parse(createdAt??"");
    dateString="${newData.day} ${getMonthName(newData.month)}, ${newData.year} ${formattedTime(newData)}";
    return dateString;
  }
  static String formattedTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }
 static  String convertTo12HourFormat(String time24) {
    List<String> parts = time24.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    String period = hour < 12 ? 'AM' : 'PM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }
  static String getDataFormat(String? createdAt) {
    String dateString="";
    final newData=DateTime.parse(createdAt??"");
    dateString="${newData.day} ${getMonthName(newData.month)}, ${newData.year}";
    return dateString;
  }
  static String  getYYYMMDDFormatDate(String dateString ){
    DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);
    String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    return formattedDate; // Output: 2024-02-13
  }
  static String getMonthName(int monthCode){
    switch(monthCode){
      case 1:{
        return "Jan";
      }
      case 2:{
        return "Feb";
      }
      case 3:{
        return "March";
      }
      case 4:{
        return "April";
      }
      case 5:{
        return "May";
      }
      case 6:{
        return "June";
      }
      case 7:{
        return "July";
      }
      case 8:{
        return "Aug";
      }
      case 9:{
        return "Sep";
      }
      case 10:{
        return "Oct";
      }
      case 11:{
        return "Nov";
      }
      case 12:{
        return "Des";
      }
      default:{
        return "";
      }

    }
  }

  static String getTodayDateInString() {
    final dateParse =  DateFormat('yyyy-MM-dd').parse((DateTime.now().toString()));
    return getYYYMMDDFormatDate(dateParse.toString());

  }
  static String getTodayTimeInString() {
    return  DateFormat('hh:mm').format(DateTime.now());
  }
  static bool checkIfTimePassed(String time, String selectedDate) {
    // Check if the selectedDate is empty
    if (selectedDate == "") {
      return true;
    }

    DateTime parseSelectedDate = DateTime.parse(selectedDate);
    // Parse the current date
    DateTime now = DateTime.now();

    // Remove time components from both dates
    DateTime selectedDateOnly = DateTime(parseSelectedDate.year, parseSelectedDate.month, parseSelectedDate.day);
    DateTime todayOnly = DateTime(now.year, now.month, now.day);

    // Calculate the difference in days
    int differenceInDays = selectedDateOnly.difference(todayOnly).inDays;

    switch (differenceInDays) {
      case 0: // Same day
        DateFormat format = DateFormat("HH:mm");
        DateTime inputTime = format.parse(time);

        // Combine input time with today's date
        DateTime todayTime = DateTime(now.year, now.month, now.day, inputTime.hour, inputTime.minute);

        // Compare times
        if (todayTime.isBefore(now)) {
          // The time has passed.
          return true;
        } else {
          // The time has not passed.
          return false;
        }

      case -1: // One day before
        return true;

      default: // Neither today nor one day before
        return false;
    }
  }
}