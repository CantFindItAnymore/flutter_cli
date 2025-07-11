// ignore_for_file: constant_identifier_names

import 'package:flutter_cli/core/index.dart';

enum MoneyFormats {
  NORMAL, //保留两位小数(6.00元)
  END_INTEGER, //去掉末尾'0'(6.00元 -> 6元, 6.60元 -> 6.6元)
  YUAN_INTEGER, //整元(6.00元 -> 6元)
}

enum MoneyUnit {
  NORMAL, // 6.00
  YUAN, // ¥6.00
  YUAN_ZH, // 6.00元
  DOLLAR, // $6.00
}

/**
 * @Author: Sky24n
 * @GitHub: https://github.com/Sky24n
 * @Description: Money Util.
 * @Date: 2018/9/29
 */

/// Money Util.
class MoneyUtil {
  static const String yuan = '¥';
  static const String yuanZh = '元';
  static const String dollar = '\$';

  /// fen to yuan, format output.
  /// 分 转 元, format格式输出.
  static String changeF2Y(int amount,
      {MoneyFormats format = MoneyFormats.NORMAL}) {
    String moneyTxt;
    double yuan = NumUtil.divide(amount, 100);
    switch (format) {
      case MoneyFormats.NORMAL:
        moneyTxt = yuan.toStringAsFixed(2);
        break;
      case MoneyFormats.END_INTEGER:
        if (amount % 100 == 0) {
          moneyTxt = yuan.toInt().toString();
        } else if (amount % 10 == 0) {
          moneyTxt = yuan.toStringAsFixed(1);
        } else {
          moneyTxt = yuan.toStringAsFixed(2);
        }
        break;
      case MoneyFormats.YUAN_INTEGER:
        moneyTxt = (amount % 100 == 0)
            ? yuan.toInt().toString()
            : yuan.toStringAsFixed(2);
        break;
    }
    return moneyTxt;
  }

  /// fen str to yuan, format & unit  output.
  /// 分字符串 转 元, format 与 unit 格式 输出.
  static String changeFStr2YWithUnit(String amountStr,
      {MoneyFormats format = MoneyFormats.NORMAL,
      MoneyUnit unit = MoneyUnit.NORMAL}) {
    int amount = int.parse(amountStr);
    return changeF2YWithUnit(amount, format: format, unit: unit);
  }

  /// fen to yuan, format & unit  output.
  /// 分 转 元, format 与 unit 格式 输出.
  static String changeF2YWithUnit(int amount,
      {MoneyFormats format = MoneyFormats.NORMAL,
      MoneyUnit unit = MoneyUnit.NORMAL}) {
    return withUnit(changeF2Y(amount, format: format), unit);
  }

  /// yuan, format & unit  output.(yuan is int,double,str).
  /// 元, format 与 unit 格式 输出.
  static String changeYWithUnit(Object yuan, MoneyUnit unit,
      {MoneyFormats? format}) {
    String yuanTxt = yuan.toString();
    if (format != null) {
      int amount = changeY2F(yuan);
      yuanTxt = changeF2Y(amount.toInt(), format: format);
    }
    return withUnit(yuanTxt, unit);
  }

  /// yuan to fen.F
  /// 元 转 分，
  static int changeY2F(Object yuan) {
    return NumUtil.multiplyDecStr(yuan.toString(), '100').toBigInt().toInt();
  }

  /// with unit.
  /// 拼接单位.
  static String withUnit(String moneyTxt, MoneyUnit unit) {
    switch (unit) {
      case MoneyUnit.YUAN:
        moneyTxt = yuan + moneyTxt;
        break;
      case MoneyUnit.YUAN_ZH:
        moneyTxt = moneyTxt + yuanZh;
        break;
      case MoneyUnit.DOLLAR:
        moneyTxt = dollar + moneyTxt;
        break;
      default:
        break;
    }
    return moneyTxt;
  }
}
