import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/chart_data_model.dart';

class LineChartWidget extends StatefulWidget {
  final List<ChartData> chartData;

  const LineChartWidget({super.key, required this.chartData});

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  List<Color> gradientColors = [
    Colors.cyan,
    Colors.blue,
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              showAvg ? avgData() : mainData(),
            ),
          ),
        ),
        // Uncomment this if you want a toggle button for average data
        // SizedBox(
        //   width: 60,
        //   height: 34,
        //   child: TextButton(
        //     onPressed: () {
        //       setState(() {
        //         showAvg = !showAvg;
        //       });
        //     },
        //     child: Text(
        //       'avg',
        //       style: TextStyle(
        //         fontSize: 12,
        //         color: showAvg ? Colors.white.withOpacity(0.5) : Colors.white,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  List<double> calculateAverageWeights(List<ChartData> weightData) {
    if (weightData.isEmpty) return [];

    int length = weightData.length;
    double firstWeight = weightData.first.value;
    double middleWeight = weightData[length ~/ 2].value;
    double lastWeight = weightData.last.value;

    return [firstWeight, middleWeight, lastWeight];
  }

  List<String> calculateDateLabels(List<ChartData> weightData) {
    if (weightData.isEmpty) return [];

    int length = weightData.length;
    String firstDate = DateFormat('MM/dd').format(weightData.first.date);
    String middleDate = DateFormat('MM/dd').format(weightData[length ~/ 2].date);
    String lastDate = DateFormat('MM/dd').format(weightData.last.date);

    return [firstDate, middleDate, lastDate];
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    List<String> dateLabels = calculateDateLabels(widget.chartData);

    // Display only labels for the first, middle, and last dates
    if (value.toInt() == 0) {
      return SideTitleWidget(
        // axisSide: meta.axisSide,
        meta:  TitleMeta(
          min: 0, // Minimum value on the axis
          max: 10, // Maximum value on the axis
          parentAxisSize: 100, // Size of the parent axis (can be dynamic)
          axisPosition: 0, // Position on the axis (based on the value)
          appliedInterval: 1, // Interval applied for the titles
          sideTitles: SideTitles(showTitles: true), // SideTitles settings
          formattedValue: '', // Formatted value for the title
          axisSide: AxisSide.bottom, // Specify the axis side
          rotationQuarterTurns: 0, // No rotation by default
        ),
        child: Text(dateLabels[0], style: style),
      );
    } else if (value.toInt() == widget.chartData.length ~/ 2) {
      return SideTitleWidget(
        //   axisSide: meta.axisSide,
        meta:  TitleMeta(
          min: 0, // Minimum value on the axis
          max: 10, // Maximum value on the axis
          parentAxisSize: 100, // Size of the parent axis (can be dynamic)
          axisPosition: 0, // Position on the axis (based on the value)
          appliedInterval: 1, // Interval applied for the titles
          sideTitles: SideTitles(showTitles: true), // SideTitles settings
          formattedValue: '', // Formatted value for the title
          axisSide: AxisSide.bottom, // Specify the axis side
          rotationQuarterTurns: 0, // No rotation by default
        ),
        child: Text(dateLabels[1], style: style),
      );
    } else if (value.toInt() == widget.chartData.length - 1) {
      return SideTitleWidget(
        //  axisSide: meta.axisSide,
        meta:  TitleMeta(
          min: 0, // Minimum value on the axis
          max: 10, // Maximum value on the axis
          parentAxisSize: 100, // Size of the parent axis (can be dynamic)
          axisPosition: 0, // Position on the axis (based on the value)
          appliedInterval: 1, // Interval applied for the titles
          sideTitles: SideTitles(showTitles: true), // SideTitles settings
          formattedValue: '', // Formatted value for the title
          axisSide: AxisSide.bottom, // Specify the axis side
          rotationQuarterTurns: 0, // No rotation by default
        ),
        child: Text(dateLabels[2], style: style),
      );
    } else {
      return const SizedBox.shrink(); // Hide other values
    }
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    List<double> avgWeights = calculateAverageWeights(widget.chartData);

    if (avgWeights.isEmpty) return const SizedBox.shrink();

    // Display only labels for the first, middle, and last weights
    if (value == avgWeights[0] || value == avgWeights[1] || value == avgWeights[2]) {
      return SideTitleWidget(
        // axisSide: meta.axisSide,
        meta:  TitleMeta(
          min: 0, // Minimum value on the axis
          max: 10, // Maximum value on the axis
          parentAxisSize: 100, // Size of the parent axis (can be dynamic)
          axisPosition: 0, // Position on the axis (based on the value)
          appliedInterval: 1, // Interval applied for the titles
          sideTitles: SideTitles(showTitles: true), // SideTitles settings
          formattedValue: '', // Formatted value for the title
          axisSide: AxisSide.bottom, // Specify the axis side
          rotationQuarterTurns: 0, // No rotation by default
        ),
        child: Text(value.toStringAsFixed(1), style: style),
      );
    } else {
      return const SizedBox.shrink(); // Hide other values
    }
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: false,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1, // Adjust this interval if necessary
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData:    FlBorderData(
        show: true,
        border: Border(
          bottom:
          BorderSide(color: Colors.grey.shade400, width: 2),
          left:  BorderSide(color: Colors.grey.shade400, width: 2),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: (widget.chartData.length - 1).toDouble(),
      minY: widget.chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 5,
      maxY: widget.chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 5,
      lineBarsData: [
        LineChartBarData(
          spots: widget.chartData.asMap().entries.map((e) {
            int index = e.key;
            ChartData data = e.value;
            return FlSpot(index.toDouble(), data.value);
          }).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withValues(
                alpha: (0.3 * 255),  // equivalent to opacity 0.3
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    List<double> avgWeights = calculateAverageWeights(widget.chartData);
    List<FlSpot> avgSpots = [
      FlSpot(0, avgWeights[0]),
      FlSpot((widget.chartData.length / 2).toDouble(), avgWeights[1]),
      FlSpot((widget.chartData.length - 1).toDouble(), avgWeights[2]),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: 1, // Adjust this interval if necessary
            getTitlesWidget: leftTitleWidgets,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData:
      FlBorderData(
        show: true,
        border: Border(
          bottom:
          BorderSide(
              color: Colors.red.withValues(
                alpha: (0.2 * 255),  // equivalent to opacity 0.2
              ),
              width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: (widget.chartData.length - 1).toDouble(),
      minY: avgWeights.reduce((a, b) => a < b ? a : b) - 5,
      maxY: avgWeights.reduce((a, b) => a > b ? a : b) + 5,
      lineBarsData: [
        LineChartBarData(
          spots: avgSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}
